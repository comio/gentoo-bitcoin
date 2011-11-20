# Copyright 2010-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DB_VER="4.8"
WX_GTK_VER="2.9"

inherit db-use eutils versionator wxwidgets

DESCRIPTION="An end-user wxWidgets GUI for the Bitcoin crypto-currency"
HOMEPAGE="http://bitcoin.org/"
myP="bitcoin-${PV/_/}"
SRC_URI="mirror://sourceforge/bitcoin/test/${myP}-src.tar.gz
	eligius? ( http://luke.dashjr.org/programs/bitcoin/files/0.3.22-eligius_sendfee.patch )
"

LICENSE="MIT ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+eligius nls ssl upnp +volatile-fees"
LANGS="cs de eo es fr it lt nl pt ru zh_CN"

for X in ${LANGS}; do
	IUSE="$IUSE linguas_$X"
done

RDEPEND="
	>=dev-libs/boost-1.41.0
	dev-libs/crypto++
	dev-libs/openssl[-bindist]
	nls? (
		sys-devel/gettext
	)
	upnp? (
		<net-libs/miniupnpc-1.6
	)
	sys-libs/db:$(db_ver_to_slot "${DB_VER}")
	>=app-admin/eselect-wxwidgets-0.7-r1
	x11-libs/wxGTK:2.9[X]
"
DEPEND="${RDEPEND}
	>=app-shells/bash-4.1
"

S="${WORKDIR}/${myP}"

src_prepare() {
	cd src || die
	cp "${FILESDIR}/Makefile.gentoo" "Makefile" || die

	epatch "${FILESDIR}/Limit-response-to-getblocks-to-half-of-output-buffer.patch"
	epatch "${FILESDIR}/Support-for-boost-filesystem-version-3.patch"

	use eligius && epatch "${DISTDIR}/0.3.22-eligius_sendfee.patch"

	einfo 'Since 0.3.20.2 was released, suggested fees have been reduced from'
	einfo ' 0.01 BTC to 0.0005 BTC (per KB)'
	if use volatile-fees; then
		einfo '    USE=volatile-fees enabled, adjusting...'
		epatch "${FILESDIR}/0.3.22-Backport-reduced-fees-of-0.0005-BTC-send-accept-and-.patch"
	else
		ewarn '    Enable USE=volatile-fees to apply fee adjustments'
	fi
}

src_compile() {
	local OPTS=()
	local BOOST_PKG BOOST_VER BOOST_INC

	OPTS+=("CXXFLAGS=${CXXFLAGS}")
	OPTS+=( "LDFLAGS=${LDFLAGS}")

	OPTS+=("DB_CXXFLAGS=-I$(db_includedir "${DB_VER}")")
	OPTS+=("DB_LDFLAGS=-ldb_cxx-${DB_VER}")

	BOOST_PKG="$(best_version 'dev-libs/boost')"
	BOOST_VER="$(get_version_component_range 1-2 "${BOOST_PKG/*boost-/}")"
	BOOST_VER="$(replace_all_version_separators _ "${BOOST_VER}")"
	BOOST_LIB="/usr/include/boost-${BOOST_VER}"
	OPTS+=("BOOST_CXXFLAGS=-I${BOOST_LIB}")
	OPTS+=("BOOST_LIB_SUFFIX=-${BOOST_VER}")

	use ssl  && OPTS+=(USE_SSL=1)
	use upnp && OPTS+=(USE_UPNP=1)

	cd src || die
	emake "${OPTS[@]}" bitcoin
}

src_install() {
	newbin src/bitcoin ${PN}
	insinto /usr/share/pixmaps
	doins "share/pixmaps/bitcoin.ico"
	make_desktop_entry ${PN} "wxBitcoin" "/usr/share/pixmaps/bitcoin.ico" "Network;P2P"

	if use nls; then
		for val in ${LANGS}
		do
			if use "linguas_$val"; then
				vall="$(tr 'A-Z' 'a-z' <<<"$val")"
				mv "locale/$vall/LC_MESSAGES/bitcoin.mo" "$val.mo" &&
				domo "$val.mo" || die "failed to install $val locale"
			fi
		done
	fi
}

pkg_postinst() {
	einfo "${CATEGORY}/${PN} no longer installs the 'bitcoin' symlink."
	einfo "To run it, you must use '${PN}'"
	einfo "Please note that ${PN} is no longer maintained upstream,"
	einfo "and future development is taking place on net-p2p/bitcoin-qt"
}