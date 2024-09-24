#!/usr/bin/env bash

set -u

ok=0

for t in t/*.nc; do
  tn="${t%.nc}"
  out="$(runghc -Wno-x-partial nci.hs "$t" < "$tn.in" | od -tx1c; exit ${PIPESTATUS[0]})"
  if [ $? = 0 ] && diff -u <(od -tx1c "$tn.out") <(echo "$out"); then
    echo "$tn: ok"
  else
    echo "$tn: ng"
    ok=1
  fi
done

if [ $ok = 0 ]; then
  echo 'all ok'
fi
exit $ok
