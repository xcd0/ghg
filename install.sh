#!/bin/sh

author_name=Songmu
project_name=ghg
os=windows
arch=amd64

# githubのreleaseから最新のバイナリをダウンロードするスクリプト
# * 前提
#   * releaseにおいてあるファイルのファイル名がOSやアーキテクチャを判断できる一定の書式に則っていること
#   * 生の実行ファイルかzip,gzipで圧縮されたファイルであること
# * 要件
#   * busyboxに入っている程度のコマンドで使用できること
#     * curlとかダメ
#     * (参考) busybox for windowsで使えるコマンド https://frippery.org/busybox/
#       [, [[, ar, arch, ascii, ash, awk, base32, base64, basename, bash, bc, bunzip2, busybox, bzcat, bzip2, cal, cat, 
#       chattr, chmod, cksum, clear, cmp, comm, cp, cpio, crc32, cut, date, dc, dd, df, diff, dirname, dos2unix, dpkg,  
#       dpkg-deb, du, echo, ed, egrep, env, expand, expr, factor, false, fgrep, find, fold, free, fsync, ftpget,        
#       ftpput, getopt, grep, groups, gunzip, gzip, hd, head, hexdump, httpd, iconv, id, inotifyd, install, ipcalc, jn, 
#       kill, killall, less, link, ln, logname, ls, lsattr, lzcat, lzma, lzop, lzopcat, make, man, md5sum, mkdir,
#       mktemp, mv, nc, nl, nproc, od, paste, patch, pdpmake, pgrep, pidof, pipe_progress, pkill, printenv, printf, ps, 
#       pwd, readlink, realpath, reset, rev, rm, rmdir, rpm, rpm2cpio, sed, seq, sh, sha1sum, sha256sum, sha3sum,       
#       sha512sum, shred, shuf, sleep, sort, split, ssl_client, stat, strings, su, sum, sync, tac, tail, tar, tee,      
#       test, time, timeout, touch, tr, true, truncate, ts, tsort, ttysize, uname, uncompress, unexpand, uniq,
#       unix2dos, unlink, unlzma, unlzop, unxz, unzip, uptime, usleep, uudecode, uuencode, vi, watch, wc, wget, which,  
#       whoami, whois, xargs, xxd, xz, xzcat, yes, zcat

now=`date +%Y%m%d.%H.%M.%S.%3N`
working_dir=tmp_$now

if t="`mkdir $working_dir 2>&1`"  && [ "$t" != "" ]; then
	now=`date +%Y%m%d.%H.%M.%S.%3N`
	working_dir=tmp_$now
	if t="`mkdir $working_dir 2>&1`"  && [ "$t" != "" ]; then
		echo 作業ディレクトリが作成できません。
		exit 1
	fi
fi
cd $working_dir
working_dir=`pwd`

# githubのapiを使用してリポジトリの情報が入ったjsonを得る
wget -q https://api.github.com/repos/${author_name}/${project_name}/releases/latest

# ダウンロード用にurlを生成する。
tmp=`cat latest | grep name`
tag_name=`echo "$tmp" | grep tag_name | sed 's/"//g; s/,//g' | awk '{print $2}'`
archive_name=`echo "$tmp" | grep windows | grep amd | sed 's/"//g; s/,//g' | awk '{print $2}'`
target_url=https://github.com/${author_name}/${project_name}/releases/download/${tag_name}/${archive_name}

# ダウンロードする
wget -q $target_url

# 展開してbinに実行ファイルのパスを入れる
bin=$archive_name
if [ $(file --mime $archive_name | awk '{print $2}' | grep "exec") ]; then
	: # 圧縮されていない実行ファイル
elif [ $(file --mime $archive_name | awk '{print $2}' | grep "/x-tar") ]; then
	# tar ball
	tar xf $archive_name
	bin=$(tar tf $archive_name | xargs file --mime | nl -ba | grep exec | awk '{print $2}' | sed 's/://g')
elif [ $(file --mime $archive_name | awk '{print $2}' | grep "/gzip") ]; then
	# tar.gz
	tar xf $archive_name
	bin=$(tar tf $archive_name | xargs file --mime | nl -ba | grep exec | awk '{print $2}' | sed 's/://g')
elif [ $(file --mime $archive_name | awk '{print $2}' | grep "/zip") ]; then
	# zip
	unzip $archive_name >/dev/null
	bin=$(unzip -l $archive_name | awk '{print $4}' | grep / | xargs file --mime | nl -ba | grep exec | awk '{print $2}' | sed 's/://g')
else
	echo "ファイルの拡張子が対応していません: $archive_name"
fi

mv $bin ..
cd ..
rm -rf $working_dir
bin=$(echo $bin | xargs basename)
echo $bin is downloaded. Success!

