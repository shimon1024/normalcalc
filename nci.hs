import System.Environment
import System.IO
import qualified Data.ByteString as BS

data U = Fn (IO U -> IO U) | Pr (IO U) | MI Integer
data State = Code | Comment

liftU :: (IO U -> IO U) -> IO U
liftU f =
  return $ Fn $ \x ->
  f x

liftU2 :: (IO U -> IO U -> IO U) -> IO U
liftU2 f =
  return $ Fn $ \x ->
  return $ Fn $ \y ->
  f x y

liftU3 :: (IO U -> IO U -> IO U -> IO U) -> IO U
liftU3 f =
  return $ Fn $ \x ->
  return $ Fn $ \y ->
  return $ Fn $ \z ->
  f x y z

($$) :: IO U -> IO U -> IO U
($$) f x = do
  Fn f' <- f
  f' x

s :: IO U
s = liftU3 $ \x y z -> (x $$ z) $$ (y $$ z)

k :: IO U
k = liftU2 $ \x _ -> x

castInt :: (Integral a, Integral b, Bounded b) => a -> b
castInt x
  | x' >= toInteger (minBound `asTypeOf` to) &&
    x' <= toInteger (maxBound `asTypeOf` to)
    = to
  | otherwise = undefined
  where
    x' = toInteger x
    to = fromIntegral x

dec :: IO Integer -> IO U
dec mi = mi >>= flip go (k $$ (s $$ k $$ k))
  where
    go 0 n = n
    go mi n = go (mi - 1) $ (s $$ (s $$ (k $$ s) $$ k)) $$ n

enc :: IO U -> IO Integer
enc n = do
  MI mi <- n $$ suc $$ zero
  return mi
  where
    suc = liftU $ \mi -> do
      MI mi' <- mi
      return $ MI $ mi' + 1
    zero = return $ MI 0

get :: IO Integer
get = do
  eof <- isEOF
  if eof
    then return 256
    else toInteger . BS.head <$> BS.hGet stdin 1

put :: IO Integer -> IO ()
put n = n >>= BS.hPut stdout . BS.pack . (:[]) . castInt

interpret :: Handle -> State -> IO U
interpret h st@Code = hGetChar h >>= \c -> case c of
  '`'  -> do
    f <- interpret h st
    x <- interpret h st
    (return f) $$ (return x)
  '*'  -> s
  '/'  -> k
  '|'  -> liftU2 $ \p f -> do
    Pr p' <- p
    x <- p'
    f $$ (return x)
  '_'  -> liftU $ \x -> return $ Pr x
  ','  -> liftU $ \_ -> return $ Pr $ dec get
  '.'  -> liftU $ \n -> return $ Pr $ put (enc n) >> (s $$ k $$ k)
  '#'  -> interpret h Comment
  _    -> interpret h st
interpret h st@Comment = hGetChar h >>= \c -> case c of
  '\n' -> interpret h Code
  _    -> interpret h st

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  args <- getArgs
  withFile (head args) ReadMode $ \h ->
    interpret h Code >>= \(Pr p) -> p >> return ()
