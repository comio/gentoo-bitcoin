# Copyright 2010-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/bitcoin-tx/bitcoin-tx-0.10.0.ebuild,v 1.3 2015/03/14 19:19:16 blueness Exp $

EAPI=5

BITCOINCORE_COMMITHASH="047a89831760ff124740fe9f58411d57ee087078"
BITCOINCORE_LJR_DATE="20150311"
BITCOINCORE_IUSE=""
BITCOINCORE_NEED_LIBSECP256K1=1
inherit bitcoincore

DESCRIPTION="Command-line Bitcoin transaction tool"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86 ~amd64-linux ~x86-linux"

src_prepare() {
	bitcoincore_prepare
	bitcoincore_autoreconf
}

src_configure() {
	bitcoincore_conf \
		--enable-util-tx
}
