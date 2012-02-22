# Copyright 2010-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DB_VER="4.8"

inherit db-use eutils versionator

DESCRIPTION="Original Bitcoin crypto-currency wallet for automated services"
HOMEPAGE="http://bitcoin.org/"
myP="bitcoin-${PV/_/}"
SRC_URI="mirror://sourceforge/bitcoin/test/${myP}-src.tar.gz
	bip17? ( http://luke.dashjr.org/programs/bitcoin/files/bip17/bip17_v${PV}.patch -> bip17_v${PV}_r2.patch )
	eligius? ( http://luke.dashjr.org/programs/bitcoin/files/0.3.22-eligius_sendfee.patch )
"

LICENSE="MIT ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+bip17 +eligius ssl upnp +volatile-fees"

RDEPEND="
	>=dev-libs/boost-1.41.0
	dev-libs/crypto++
	dev-libs/openssl[-bindist]
	upnp? (
		<net-libs/miniupnpc-1.6
	)
	sys-libs/db:$(db_ver_to_slot "${DB_VER}")[cxx]
"
DEPEND="${RDEPEND}
	>=app-shells/bash-4.1
"

S="${WORKDIR}/${myP}"

pkg_setup() {
	local UG='bitcoin'
	enewgroup "${UG}"
	enewuser "${UG}" -1 -1 /var/lib/bitcoin "${UG}"
}

src_prepare() {
	cd src || die
	cp "${FILESDIR}/Makefile.gentoo" "Makefile" || die

	epatch "${FILESDIR}/Limit-response-to-getblocks-to-half-of-output-buffer.patch"

	use bip17 && epatch "${DISTDIR}/bip17_v${PV}_r2.patch"

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
	BOOST_INC="/usr/include/boost-${BOOST_VER}"
	OPTS+=("BOOST_CXXFLAGS=-I${BOOST_INC}")
	OPTS+=("BOOST_LIB_SUFFIX=-${BOOST_VER}")

	use ssl  && OPTS+=(USE_SSL=1)
	use upnp && OPTS+=(USE_UPNP=1)

	cd src || die
	emake "${OPTS[@]}" ${PN}
}

src_install() {
	dobin src/${PN}

	insinto /etc/bitcoin
	newins "${FILESDIR}/bitcoin.conf" bitcoin.conf
	fowners bitcoin:bitcoin /etc/bitcoin/bitcoin.conf
	fperms 600 /etc/bitcoin/bitcoin.conf

	newconfd "${FILESDIR}/bitcoin.confd" ${PN}
	newinitd "${FILESDIR}/bitcoin.initd" ${PN}

	keepdir /var/lib/bitcoin/.bitcoin
	fperms 700 /var/lib/bitcoin
	fowners bitcoin:bitcoin /var/lib/bitcoin/
	fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
	dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf

	dodoc doc/README
}