# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

PYTHON_COMPAT="python2_7"

inherit eutils git-2 python-distutils-ng

DESCRIPTION="Graphical speculation platform, supports Bitstamp, BTC-e, CampBX, MtGox."
HOMEPAGE="https://github.com/3M3RY/${PN}"
EGIT_REPO_URI="git://github.com/3M3RY/tulpenmanie.git \
			   https://github.com/3M3RY/tulpenmanie.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="dev-python/PyQt4"
DEPEND="${RDEPEND}"

pkg_preinst() {
	cd "${S}/graphics"
	for SIZE in 16 22 24 32 36 48 64 72 96 128 192 256 ; do
		newicon --size ${SIZE} icon-${SIZE}x${SIZE}.png ${PN}.png
	done
	make_desktop_entry ${PN} Tulpenmanie ${PN} "Network;Economy;Finance"
}
