# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

inherit eutils fdo-mime python-any-r1 git-2

DESCRIPTION="Armory is a Bitcoin client, offering a dozen innovative features not found anywhere else."
HOMEPAGE="http://bitcoinarmory.com/"
EGIT_REPO_URI="git://github.com/etotheipi/BitcoinArmory.git"
EGIT_COMMIT="v${PV}"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

COMMON_DEPEND="${PYTHON_DEPS}
			   dev-libs/crypto++
			   dev-libs/leveldb
			   dev-python/PyQt4[X]
			   dev-python/twisted-core"

DEPEND="${COMMON_DEPEND}
		dev-lang/swig
		x11-misc/xdg-utils"

RDEPEND="${COMMON_DEPEND}
		 dev-python/psutil"

src_prepare() {
	epatch "${FILESDIR}/snappy-0.91.patch"

	sed -i "s|python /usr/lib/|${EPYTHON} $( python_get_sitedir)/|" \
		dpkgfiles/*.desktop || die "failed to modify desktop entry exec parameter"
}

src_install() {
	python_moduleinto ${PN}
	python_domodule armoryengine extras jsonrpc ui *.py _CppBlockUtils.so

	dodoc README

	insinto /usr/share/armory/img
	doins img/*

	domenu dpkgfiles/*.desktop
	validate_desktop_entries

	echo "python2 $(python_get_sitedir)/armory/ArmoryQt.py $@" > "${T}/armory"
	dobin "${T}/armory"
}

pkg_postinst() {
	xdg-icon-resource install --novendor --context apps --size 64 /usr/share/armory/img/armory_icon_64x64.png armoryicon
	xdg-icon-resource install --novendor --context apps --size 64 /usr/share/armory/img/armory_icon_64x64.png armoryofflineicon
	xdg-icon-resource install --novendor --context apps --size 64 /usr/share/armory/img/armory_icon_green_64x64.png armorytestneticon
}

pkg_postrm() { fdo-mime_desktop_database_update; }
