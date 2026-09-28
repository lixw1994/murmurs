require 'minitest/autorun'
require 'tmpdir'
require 'stringio'

load File.expand_path('generate', __dir__)

class L10nGenerateTest < Minitest::Test
  HEADER = %("key","comment","platforms","en",zh-Hans\n)

  def parse(body)
    L10n.parse(HEADER + body)
  end

  def test_comment_rows_produce_no_keys
    _, entries, = parse(%(# General #\n"app_name","App","apple","Murmurs",Murmurs\n))
    assert_equal ["app_name"], entries.map(&:key)
  end

  def test_empty_platforms_fails_with_key_name
    error = assert_raises(L10n::Error) { parse(%("app_name","App","","Murmurs",Murmurs\n)) }
    assert_includes error.message, "app_name"
  end

  def test_unknown_platform_fails
    assert_raises(L10n::Error) { parse(%("app_name","App","android","Murmurs",Murmurs\n)) }
  end

  def test_missing_translation_is_reported_and_falls_back
    _, entries, missing = parse(%("export","Export","apple","Export",\n))
    assert_equal [["export", "zh-Hans"]], missing
    assert_equal "Export", entries[0].values["zh-Hans"]
  end

  def test_platform_filtering
    _, entries, = parse(<<~CSV)
      "apple_only","","apple","A",甲
      "web.only","","web","W",乙
      "shared","","apple web","S",丙
    CSV
    assert_equal %w[apple_only shared], L10n.for_platform(entries, "apple").map(&:key)
    assert_equal %w[web.only shared], L10n.for_platform(entries, "web").map(&:key)
  end

  def test_web_placeholders
    assert_equal "Summary for %{0}", L10n.web_value("Summary for %@")
    assert_equal "%{0} of %{1}", L10n.web_value("%d of %@")
    assert_equal "%{1} then %{0}", L10n.web_value("%2$@ then %1$@")
    assert_equal "100%", L10n.web_value("100%%")
  end

  def test_literal_double_braces_are_untouched
    assert_equal "Diary for {{date}}", L10n.web_value("Diary for {{date}}")
  end

  def test_web_json_nests_and_sorts
    _, entries, = parse(<<~CSV)
      "web.landing.title","","web","Murmurs",Murmurs
      "web.common.home","","web","Home",首页
      "privacy_policy","","apple web","Privacy Policy",隐私权政策
    CSV
    json = L10n.web_json(entries, "en")
    assert_equal({ "privacy_policy" => "Privacy Policy",
                   "web" => { "common" => { "home" => "Home" }, "landing" => { "title" => "Murmurs" } } },
                 JSON.parse(json))
    assert_equal ["privacy_policy", "web"], JSON.parse(json).keys
    assert json.end_with?("\n")
  end

  def test_web_key_collision_fails
    _, entries, = parse(<<~CSV)
      "web.nav","","web","Nav",导航
      "web.nav.home","","web","Home",首页
    CSV
    assert_raises(L10n::Error) { L10n.web_json(entries, "en") }
  end

  def test_apple_outputs_keep_existing_format
    _, entries, = parse(<<~CSV)
      "@CFBundleDisplayName","App name","apple","Murmurs",Murmurs
      "app_name","App name","apple","Murmurs",Murmurs
      "web.only","","web","W",乙
    CSV
    apple = L10n.for_platform(entries, "apple")
    assert_equal %(/*App name*/\n"app_name" = "Murmurs";\n), L10n.apple_strings(apple, "en")
    assert_equal %(CFBundleDisplayName = "Murmurs";\n), L10n.apple_plist_strings(apple, "en")
    assert_includes L10n.apple_swift(apple), %(case app_name = "app_name")
    refute_includes L10n.apple_swift(apple), "web"
  end

  def test_run_is_idempotent
    Dir.mktmpdir do |dir|
      csv = File.join(dir, "L.csv")
      File.write(csv, HEADER + %("app_name","App","apple web","Murmurs",Murmurs\n))
      opts = { swift: File.join(dir, "Keys.swift"), root: File.join(dir, "apple"), web: File.join(dir, "web") }
      L10n.run(csv, **opts, err: StringIO.new)
      first = Dir.glob("#{dir}/**/*").reject { |f| File.directory?(f) }.sort.map { |f| [f, File.mtime(f), File.read(f)] }
      sleep 1.1
      L10n.run(csv, **opts, err: StringIO.new)
      second = Dir.glob("#{dir}/**/*").reject { |f| File.directory?(f) }.sort.map { |f| [f, File.mtime(f), File.read(f)] }
      assert_equal first, second
    end
  end
end
