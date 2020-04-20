#!/bin/bash
file="bootstrap.dat"
file_sha256="sha256.txt"
header=`cat header.md`
footer=`cat footer.md`

# pass network name as a param
do_the_job() {
  network=$1
  date=`date -u`
  date_fmt=`date -u +%Y-%m-%d`
  s3networkPath="$s3bucket$network/"
  s3currentPath="$s3networkPath$date_fmt/"
  s3currentUrl="$s3https$network/$date_fmt/"
  linksFile="links-$network.md"
  prevLinks=`head $linksFile`
  echo "$network job - Starting..."
  max_height=$( eval cat linearize-$network.cfg | grep max_height | sed "s/max_height=//g" )
  file_zip="stpx_bootstrap_${network}_${max_height}.zip"
  # process blockchain
  ./linearize-hashes.py linearize-$network.cfg > hashlist.txt
  ./linearize-data.py linearize-$network.cfg
  # compress
  zip $file_zip $file
  # calculate checksums
  sha256sum $file > $file_sha256
  sha256sum $file_zip >> $file_sha256

  # TODO - modify upload code below. For now just exit
  echo "Successfully created file $file"
  
  # store on IPFS (make sure ipfs daemon is running first)
  ipfs_zip=$( ipfs add -Q $file_zip )
  ipfs_sha256=$( ipfs add -Q $file_sha256 )
  url_zip="https://ipfs.io/ipfs/${ipfs_zip}?filename=${file_zip}"
  url_sha256="https://ipfs.io/ipfs/${ipfs_sha256}?filename=${file_sha256}"

  size_zip=`ls -lh $file_zip | awk -F" " '{ print $5 }'`
  newLinks="Block $max_height: $date [zip]($url_zip) ($size_zip) [SHA256]($url_sha256)\n\n$prevLinks"
  echo -e "$newLinks" > $linksFile

  #cleanup
  rm hashlist.txt sha256.txt bootstrap.dat

  echo "$network job - Done!"
}

# fill the header
echo -e "$header\n" > README.md

# mainnet
#cat ~/.stash/blocks/blk0000* > $file
blocks=`~/stash/src/stash-cli -testnet=0 getblockcount`
do_the_job mainnet

# testnet
#cat ~/.stash/testnet3/blocks/blk0000* > $file
blocks=`~/stash/src/stash-cli -testnet=1 getblockcount`
do_the_job testnet

# finalize with the footer
echo -e "$footer" >> README.md

# push to github
#git add *.md
#git commit -m "$date - autoupdate"
#git push
