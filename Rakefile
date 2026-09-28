desc "Generate Apple and web localization files from l10n/Localizable.csv"
task :l10n do
  sh "l10n/generate l10n/Localizable.csv " \
     "--swift apple/Shared/Localization/LocalizedKeys.swift " \
     "--root apple/Shared/Localization " \
     "--web web/src/i18n/locales"
end
