for n in `sfdisk -s | grep sd | sed -e 's/.*sd\(.\).*/sd\1/'`
  do 
   dd bs=1M count=1000 if=/dev/zero of=/dev/${n}
  done
