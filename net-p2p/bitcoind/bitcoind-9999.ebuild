# Copyright 2010-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DB_VER="4.8"

inherit db-use eutils git

DESCRIPTION="A P2P network based digital currency."
HOMEPAGE="http://bitcoin.org/"
EGIT_PROJECT='bitcoin'
EGIT_REPO_URI="https://github.com/bitcoin/bitcoin.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug selinux ssl upnp"

DEPEND="dev-libs/boost
	dev-libs/crypto++
	dev-libs/glib
	dev-libs/openssl[-bindist]
	selinux? (
		sys-libs/libselinux
	)
	upnp? (
		net-libs/miniupnpc
	)
	sys-libs/db:$(db_ver_to_slot "${DB_VER}")
	!net-p2p/bitcoin
"
RDEPEND="${DEPEND}
	dev-util/pkgconfig
"
DEPEND="${DEPEND}
	>=app-shells/bash-4.1
"

pkg_setup() {
	local UG='bitcoin'
	ebegin "Creating ${UG} user and group"
	enewgroup "${UG}"
	enewuser "${UG}" -1 -1 /var/lib/bitcoin "${UG}"
}

src_prepare() {
	cd src
	cp "${FILESDIR}/Makefile.gentoo" "Makefile"
}

src_compile() {
	local OPTS=()
	
	OPTS+=("CXXFLAGS=${CXXFLAGS}")
	OPTS+=( "LDFLAGS=${LDFLAGS}")
	
	OPTS+=("DB_CXXFLAGS=-I$(db_includedir "${DB_VER}")")
	OPTS+=("DB_LDFLAGS=-ldb_cxx-${DB_VER}")
	
	use debug&& OPTS+=(USE_DEBUG=1)
	use ssl  && OPTS+=(USE_SSL=1)
	use upnp && OPTS+=(USE_UPNP=1)
	
	cd src
	emake "${OPTS[@]}" bitcoind || die "emake bitcoind failed";
}

src_install() {
	dobin src/bitcoind
	
	insinto /etc/bitcoin
	newins "${FILESDIR}/bitcoin.conf" bitcoin.conf
	fowners bitcoin:bitcoin /etc/bitcoin/bitcoin.conf
	fperms 600 /etc/bitcoin/bitcoin.conf
	
	newconfd "${FILESDIR}/bitcoin.confd" bitcoind
	# Init script still nonfunctional.
	newinitd "${FILESDIR}/bitcoin.initd" bitcoind
	
	keepdir /var/lib/bitcoin/.bitcoin
	fperms 700 /var/lib/bitcoin
	fowners bitcoin:bitcoin /var/lib/bitcoin/
	fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
	dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf
	
	dodoc COPYING doc/README
}
