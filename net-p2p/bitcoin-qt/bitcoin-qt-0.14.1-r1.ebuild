# Copyright 2010-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

BITCOINCORE_COMMITHASH="964a185cc83af34587194a6ecda3ed9cf6b49263"
BITCOINCORE_LJR_DATE="20170420"
BITCOINCORE_IUSE="dbus kde +libevent +knots +qrcode qt5 +http test +tor upnp +wallet zeromq"
BITCOINCORE_POLICY_PATCHES="+rbf spamfilter"
LANGS="af af_ZA ar be_BY bg bg_BG bs ca ca@valencia ca_ES cs cy da de el el_GR en en_GB eo es es_419 es_AR es_CL es_CO es_DO es_ES es_MX es_UY es_VE et et_EE eu_ES fa fa_IR fi fr fr_CA fr_FR gl he hi_IN hr hu id id_ID it it_IT ja ka kk_KZ ko_KR ku_IQ ky la lt lv_LV mk_MK mn ms_MY nb ne nl pam pl pt_BR pt_PT ro ro_RO ru ru_RU si sk sl_SI sq sr sr@latin sv ta th_TH tr tr_TR uk ur_PK uz@Cyrl vi vi_VN zh zh_CN zh_HK zh_TW"
KNOTS_LANGS="bs es_419 id si"
BITCOINCORE_NEED_LEVELDB=1
BITCOINCORE_NEED_LIBSECP256K1=1
inherit bitcoincore eutils fdo-mime gnome2-utils kde4-functions

DESCRIPTION="An end-user Qt GUI for the Bitcoin crypto-currency"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~mips ~ppc ~x86 ~amd64-linux ~x86-linux"

RDEPEND="
	dev-libs/protobuf
	qrcode? (
		media-gfx/qrencode
	)
	!qt5? ( dev-qt/qtcore:4[ssl] dev-qt/qtgui:4 )
	qt5? ( dev-qt/qtgui:5 dev-qt/qtnetwork:5 dev-qt/qtwidgets:5 )
	dbus? (
		!qt5? ( dev-qt/qtdbus:4 )
		qt5? ( dev-qt/qtdbus:5 )
	)
"
DEPEND="${RDEPEND}
	qt5? ( dev-qt/linguist-tools:5 )
	knots? (
		gnome-base/librsvg
		media-gfx/imagemagick[png]
	)
"
REQUIRED_USE="
	http? ( libevent ) tor? ( libevent ) libevent? ( http tor )
	!libevent? ( knots )
"

for lang in ${LANGS}; do
	IUSE+=" linguas_${lang}"
done

for lang in ${KNOTS_LANGS}; do
	REQUIRED_USE="${REQUIRED_USE} linguas_${lang}? ( knots )"
done

src_prepare() {
	bitcoincore_prepare

	sed -i 's/^\(Icon=\).*$/\1bitcoin-qt/;s/^\(Categories=.*\)$/\1P2P;Network;Qt;/' contrib/debian/bitcoin-qt.desktop

	local filt= yeslang= nolang= lan ts x

	for lan in $LANGS; do
		if [ ! -e src/qt/locale/bitcoin_$lan.ts ]; then
			if has $lan $KNOTS_LANGS && ! use knots; then
				# Expected
				continue
			fi
			die "Language '$lan' no longer supported. Ebuild needs update."
		fi
	done

	for ts in src/qt/locale/*.ts
	do
		x="${ts/*bitcoin_/}"
		x="${x/.ts/}"
		if ! use "linguas_$x"; then
			nolang="$nolang $x"
			rm "$ts" || die
			filt="$filt\\|$x"
		else
			yeslang="$yeslang $x"
		fi
	done
	filt="bitcoin_\\(${filt:2}\\)\\.\(qm\|ts\)"
	sed "/${filt}/d" -i 'src/qt/bitcoin_locale.qrc' || die
	sed "s/locale\/${filt}/bitcoin.qrc/" -i 'src/Makefile.qt.include' || die
	einfo "Languages -- Enabled:$yeslang -- Disabled:$nolang"

	bitcoincore_autoreconf
}

src_configure() {
	bitcoincore_conf \
		$(use_with dbus qtdbus)  \
		$(use_with qrcode qrencode)  \
		--with-gui=$(usex qt5 qt5 qt4)
}

src_install() {
	bitcoincore_src_install

	insinto /usr/share/pixmaps
	if use knots; then
		newins "src/qt/res/rendered_icons/bitcoin.ico" "${PN}.ico"
	else
		newins "share/pixmaps/bitcoin.ico" "${PN}.ico"
	fi
	insinto /usr/share/applications
	doins "contrib/debian/bitcoin-qt.desktop"

	dodoc doc/assets-attribution.md doc/bips.md doc/tor.md

	use zeromq && dodoc doc/zmq.md

	if use kde; then
		insinto /usr/share/kde4/services
		doins contrib/debian/bitcoin-qt.protocol
		dosym "../kde4/services/bitcoin-qt.protocol" "/usr/share/kservices5/bitcoin-qt.protocol"
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

update_caches() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
	buildsycoca
}

pkg_postinst() {
	update_caches
}

pkg_postrm() {
	update_caches
}
