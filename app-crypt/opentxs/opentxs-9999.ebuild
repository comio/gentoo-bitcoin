# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
PYTHON_DEPEND="python? *"

inherit eutils git-2 java-pkg-opt-2 autotools-utils python

DESCRIPTION="Open Transactions is a system for issuing and manipulating digital assets."
HOMEPAGE="https://github.com/FellowTraveler/Open-Transactions"
EGIT_REPO_URI="git://github.com/FellowTraveler/Open-Transactions.git \
			   https://github.com/FellowTraveler/Open-Transactions.git"
LICENSE="AGPL-3"

SLOT="0"
KEYWORDS=""
IUSE="java python"

COMMON_DEP="dev-libs/boost
			>=dev-libs/chaiscript-6.0.0
			dev-libs/msgpack
			dev-libs/openssl:0
			dev-libs/protobuf
			net-libs/zeromq"
RDEPEND="java? ( >=virtual/jre-1.4 )
		 ${COMMON_DEP}"
DEPEND="java? ( dev-lang/swig )
		java? ( >=virtual/jdk-1.4 )
		python? ( dev-lang/swig )
		${COMMON_DEP}"

AUTOTOOLS_AUTORECONF=1

pkg_setup() {
	use java && java-pkg-opt-2_pkg_setup
	use python && python_pkg_setup
}

src_configure() {
	local myeconfargs=(
		$(use_with java)
		$(use_with python)
	)
	use java && local JAVAC="javac"
	autotools-utils_src_configure
}

src_compile() {
	autotools-utils_src_compile
}

src_install() {
	autotools-utils_src_install
	if use python ; then
		insinto $(python_get_sitedir)
		doins swig/glue/python/otapi.py
		dosym ../../_otapi.so $(python_get_sitedir)/_otapi.so
	fi
}

pkg_postinst() {
	use python && python_mod_optimize otapi.py
}

pkg_postrm() {
	use python && python_mod_cleanup otapi.py
}
