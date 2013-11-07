# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} )

inherit distutils-r1 subversion

DESCRIPTION="Thread-safe Python bindings for LevelDB"
HOMEPAGE="https://code.google.com/p/py-leveldb/"
ESVN_REPO_URI="http://py-leveldb.googlecode.com/svn/trunk/@${PV}"

LICENSE="BSD-4"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="app-arch/snappy
		dev-libs/leveldb"
RDEPEND="${DEPEND}"
