# StartBack Plasma Translations

Translations are bundled with the widget. The catalog domain is `plasma_applet_com.github.safetyp1.startbackplasma`; the build scripts read the ID from the package metadata.

## Build

Install GNU gettext and `jq`, then run from the repository root:

```sh
sh translate/build.sh
```

This compiles the locale sources into the matching `contents/locale/` directories. Reinstall or upgrade the widget to test them. The legacy `--restartplasma` option is not supported on Plasma 6; reload Plasma separately.

## Contribute

Copy [template.pot](template.pot) to a locale-named file such as `de.po`, fill in its translations, and submit a pull request or [issue](https://github.com/safetyp1/Windows7StartMenu4KDE/issues/new) to the fork.

To extract and merge changed messages, run `sh translate/merge.sh`. These helpers are based on [Zren's translation scripts](https://github.com/Zren/plasma-applet-tiledmenu). New settings and labels may still need translation.
