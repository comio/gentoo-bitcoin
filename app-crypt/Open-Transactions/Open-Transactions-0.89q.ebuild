# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python{3_1,3_2,3_3} )

inherit eutils git-r3 java-pkg-opt-2 autotools-utils python-r1

DESCRIPTION="Financial cryptography library, API, CLI, and prototype server."
HOMEPAGE="http://opentransactions.org"
EGIT_REPO_URI="git://github.com/FellowTraveler/Open-Transactions.git \
			   https://github.com/FellowTraveler/Open-Transactions.git"
EGIT_COMMIT="7baa743c10282aa0ff48fb3527d9a2732059383b"
LICENSE="AGPL-3"

SLOT="0"
KEYWORDS="~amd64"
IUSE="doc gnome-keyring java kwallet python"
REQUIRED_USE="gnome-keyring? ( !kwallet ) kwallet? ( !gnome-keyring )"

COMMON_DEP="dev-libs/boost
			<dev-libs/chaiscript-5.0.0
			dev-libs/msgpack
			dev-libs/openssl:0
			>=dev-libs/protobuf-2.4.1
			<net-libs/zeromq-3.0.0
			gnome-keyring? ( gnome-base/gnome-keyring )
			kwallet? ( kde-base/kwallet )
			python? ( ${PYTHON_DEPS} )"

RDEPEND="java? ( >=virtual/jre-1.4 sys-apps/ed )
		 ${COMMON_DEP}"

DEPEND="java? ( dev-lang/swig )
		java? ( >=virtual/jdk-1.4 )
		python? ( dev-lang/swig )
		${COMMON_DEP}"

AUTOTOOLS_AUTORECONF=0

pkg_setup() {
	use java && java-pkg-opt-2_pkg_setup
	use python && python-r1_pkg_setup
}

src_prepare() {
	autotools-utils_src_prepare

	if use doc || use python; then
		sed -i '14i%feature("autodoc","1") ;' swig/otapi/OTAPI.i
	fi

	if use java || use python; then
		ebegin "Regenerating SWIG wrappers"
		use java && WRAPPERS="${WRAPPERS} java"
		use python && WRAPPERS="${WRAPPERS} python"
		cd swig
		sed -i "s/csharp java perl5 php python ruby tcl d/${WRAPPERS}/g" buildwrappers.sh
		./buildwrappers.sh
		eend $?
	fi
}

src_configure() {
	use java && local JAVAC="javac"
	local myeconfargs=(
		$(use_with java)
		$(use_with python))
	use gnome-keyring && myeconfargs=(${myeconfargs[@]} '--with-keyring=gnome')
	use kwallet && myeconfargs=(${myeconfargs[@]} '--with-keyring=kwallet')
	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install
	if use python ; then
		insinto $(python_get_sitedir)
		doins swig/glue/python/otapi.py
		dosym ../../_otapi.so $(python_get_sitedir)/
		python_optimize
	fi
	cd docs
	for docfile in ./*.txt ; do
		if [ ${docfile/#"INSTALL"/""} == ${docfile} ] ; then
			dodoc ${docfile}
		fi
	done
}
