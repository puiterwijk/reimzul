#!/bin/bash

# This script accepts multiple parameters
# See usage() for required parameters

function usage() {
cat << EOF

You need to call the script like this : $0 -arguments
 -s : SRPM pkg to submit to mock
 -d : disttag to use in mock
 -t : mock target/config to use and push to 
 -a : architecture
 -p : timestamp for the resultdir
 -h : display this help
EOF
}

function varcheck() {
if [ -z "$1" ] ; then
        usage
        exit 1
fi
}

while getopts "hs:d:t:a:p:" option
do
  case ${option} in
    h)
      usage
      exit 1
      ;;
    s)
      srpm_pkg=${OPTARG}
      ;;
    d)
      disttag=${OPTARG}
      ;;
    t)
      target=${OPTARG}
      ;;
    a)
      arch=${OPTARG}
      ;;
    p)
      timestamp=${OPTARG}
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

varcheck ${srpm_pkg}
varcheck ${disttag}
varcheck ${target}
varcheck ${arch}
varcheck ${timestamp}


pkg_name=$(rpm -qp --queryformat '%{name}\n' ${tmp_dir}/${srpm_pkg})
evr=$(rpm -qp --queryformat '%{version}-%{release}\n' ${tmp_dir}/${srpm_pkg})
resultdir=/srv/build/logs/${target}/${pkg_name}/${timestamp}/${evr}.${arch}/
mkdir -p ${resultdir}
mock -r ${target} --configdir=/srv/build/config/ --resultdir=${resultdir} --define "dist ${disttag}" ${tmp_dir}/$srpm_pkg >> ${resultdir}/stdout 2>>${resultdir}/stderr
export mock_exit_code="$?"
rsync -a --port=11874 /srv/build/logs/${target}/${pkg_name}/ localhost::reimzul-bstore/repo/${target}/${pkg_name}/
rm -Rf ${resultdir}
exit ${mock_exit_code}
