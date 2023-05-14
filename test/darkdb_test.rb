#!/usr/bin/env -S ruby -w

load File.expand_path("../../bin/darkdb", __FILE__)
ENV["DARKDB_ENV"] = "test"
TEST_PATH = File.expand_path("..", __FILE__)
Dir.chdir(TEST_PATH)

require "fileutils"
require "stringio"

require "minitest/autorun"

class DarkDBTest < Minitest::Test
  MIS_FILE      = "files/miss20.mis"
  MIS_FILE_BAK  = "files/miss20.mis.bak"
  MIS_FILE_ORIG = "files/miss20.mis.original"
  SAV_FILE      = "files/game0000.sav"
  SAV_FILE_BAK  = "files/game0000.sav.bak"
  SAV_FILE_ORIG = "files/game0000.sav.original"

  def create_mis_file
    FileUtils.cp(MIS_FILE_ORIG, MIS_FILE, preserve: true)
  end

  def create_sav_file
    FileUtils.cp(SAV_FILE_ORIG, SAV_FILE, preserve: true)
  end

  def create_mis_bak_file
    return if File.exist?(MIS_FILE_BAK)
    FileUtils.cp(MIS_FILE_ORIG, MIS_FILE_BAK, preserve: true)
  end

  def create_sav_bak_file
    return if File.exist?(SAV_FILE_BAK)
    FileUtils.cp(SAV_FILE_ORIG, SAV_FILE_BAK, preserve: true)
  end

  def delete_mis_bak_file
    File.delete(MIS_FILE_BAK) if File.exist?(MIS_FILE_BAK)
  end

  def test_no_table_option
    darkdb = DarkDB.new(mis_path: "test.mis")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("TABLE not specified.", error.message)
  end

  def test_no_mis_file
    darkdb = DarkDB.new(mis_path: "test.mis", table: "questdb")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("File not found: test.mis", error.message)
  end

  def test_empty_file
    darkdb = DarkDB.new(mis_path: "files/empty_file", table: "questdb")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("Empty file: files/empty_file", error.message)
  end

  def test_short_file
    darkdb = DarkDB.new(mis_path: "files/short_file", table: "questdb")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("Invalid file: files/short_file", error.message)
  end

  def test_invalid_file
    darkdb = DarkDB.new(mis_path: "files/invalid_file", table: "questdb")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("Invalid file: files/invalid_file", error.message)
  end

  def test_read_info_of_mis_file
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "info")

    expected = <<~EOS
    created_by                creator
    last_saved_by                user
    total_time              363660000 (string: 4:05:01:00)
    EOS

    assert_output(expected, "File: #{MIS_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_read_questdb_of_mis_file
    # NOTE - The following missions are examples that have:
    # "empty string" as a key (denoted below as "(blank)"):
    #     * Morbid Curiosity, miss20.mis
    #     * The Black Frog, miss20.mis
    #     * The Seven Sisters, miss22.mis
    # "number" as a key:
    #     * Violent End of Duncan Malveine, miss19.mis
    # "=" as a key prefix:
    #     * Violent End of Duncan Malveine, miss19.mis

    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "questdb")

    expected = <<~EOS
    1                          0
    (blank)                    0
    =goal_state_3              0
    DrSSecrets                 0
    goal_loot_1             1000
    goal_loot_2             2000
    goal_loot_3             3000
    goal_state_0               0
    goal_state_1               0
    goal_state_2               0
    goal_state_10              0
    GOAL_STATE_11              0
    goal_state_12              0
    map_max_page               2
    map_min_page               1
    EOS

    assert_output(expected, "File: #{MIS_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_read_questdb_of_sav_file
    darkdb = DarkDB.new(mis_path: SAV_FILE_ORIG, table: "questdb")

    expected = <<~EOS
    DrSBackStabs                0
    DrSBodyFound                0
    DrSDmgDealt                 0
    DrSKills                    0
    DrSKnockout                 0
    DrSLkPickCnt                0
    DrSLootTotal                0
    DrSObjKilled                0
    DrSPocketCnt                0
    DrSScrtCnt                  0
    DrSTime                291000 (string: 0:00:04:51)
    map_max_page                2
    map_min_page                1
    EOS

    assert_output(expected, "File: #{SAV_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_read_questcmp_of_sav_file
    darkdb = DarkDB.new(mis_path: SAV_FILE_ORIG, table: "questcmp")

    expected = <<~EOS
    Difficulty                    2
    DrSCmDmgDeal                  0
    DrSCmDmgTake                  0
    DrSCmKills                    0
    DrSCmLoot                     0
    DrSCmTime              17460000 (string: 0:04:51:00)
    TOTAL_LOOT                    0
    EOS

    assert_output(expected, "File: #{SAV_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_table_not_found
    darkdb = DarkDB.new(mis_path: SAV_FILE_ORIG, table: "info")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal("BRHEAD not found.", error.message)
  end

  def test_table_has_no_items
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG)
    File.open(MIS_FILE_ORIG, "rb") do |io|
      error = assert_raises(RuntimeError) { darkdb.read_toc_item(io, "ScrModules") }
      assert_equal("ScrModules has no items.", error.message)
    end
  end

  def test_table_option_did_you_mean_hit
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "quest")

    expected = <<~EOS
    Invalid TABLE name. Did you mean?
      questdb
      questcmp
    EOS

    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal(expected, error.message)
  end

  def test_table_option_did_you_mean_miss
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "q")
    error = assert_raises(RuntimeError) { darkdb.get() }
    assert_equal(darkdb.usage(), error.message)
  end

  def test_regex_match
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "questdb",
                        key_regex: "^goal_state")

    expected = <<~EOS
    goal_state_0            0
    goal_state_1            0
    goal_state_2            0
    goal_state_10           0
    goal_state_12           0
    EOS

    assert_output(expected, "File: #{MIS_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_regex_case_insensitive_match
    darkdb = DarkDB.new(mis_path: MIS_FILE_ORIG, table: "questdb",
                        key_regex: "^goal_state", regex_ignore_case: true)

    expected = <<~EOS
    goal_state_0            0
    goal_state_1            0
    goal_state_2            0
    goal_state_10           0
    GOAL_STATE_11           0
    goal_state_12           0
    EOS

    assert_output(expected, "File: #{MIS_FILE_ORIG}\n") { darkdb.get() }
  end

  def test_backup_created
    create_mis_file()
    delete_mis_bak_file()
    darkdb = DarkDB.new(mis_path: MIS_FILE, table: "questdb",
                        key_regex: "loot", new_value: "100")

    expected = <<~EOS
    Created backup files/miss20.mis.bak
    Wrote files/miss20.mis
    EOS

    assert_output(expected, "") do
      darkdb.set()
    end
  end

  def test_modify_string
    create_mis_file()
    create_mis_bak_file()
    darkdb1 = DarkDB.new(mis_path: MIS_FILE, table: "info",
                         key_regex: "created_by", new_value: "new_creator")

    assert_output("Wrote #{MIS_FILE}\n", "") do
      darkdb1.set()
    end

    darkdb2 = DarkDB.new(mis_path: MIS_FILE, table: "info")

    expected = <<~EOS
    created_by              new_creator
    last_saved_by                  user
    total_time                363660000 (string: 4:05:01:00)
    EOS

    assert_output(expected, "File: #{MIS_FILE}\n") { darkdb2.get() }
  end

  def test_modify_i32
    create_mis_file()
    create_mis_bak_file()
    darkdb1 = DarkDB.new(mis_path: MIS_FILE, table: "questdb",
                         key_regex: "loot", new_value: "100")

    assert_output("Wrote #{MIS_FILE}\n", "") do
      darkdb1.set()
    end

    darkdb2 = DarkDB.new(mis_path: MIS_FILE, table: "questdb",
                         key_regex: "loot")

    expected = <<~EOS
    goal_loot_1           100
    goal_loot_2           100
    goal_loot_3           100
    EOS

    assert_output(expected, "File: #{MIS_FILE}\n") { darkdb2.get() }
  end

  def test_modify_u32
    create_mis_file()
    create_mis_bak_file()
    darkdb1 = DarkDB.new(mis_path: MIS_FILE, table: "info",
                         key_regex: "time", new_value: "12345")

    assert_output("Wrote #{MIS_FILE}\n", "") do
      darkdb1.set()
    end

    darkdb2 = DarkDB.new(mis_path: MIS_FILE, table: "info")

    expected = <<~EOS
    created_by              creator
    last_saved_by              user
    total_time                12345 (string: 0:00:00:12)
    EOS

    assert_output(expected, "File: #{MIS_FILE}\n") { darkdb2.get() }
  end

  def test_modify_time_string
    create_mis_file()
    create_mis_bak_file()
    darkdb1 = DarkDB.new(mis_path: MIS_FILE, table: "info",
                         key_regex: "time", new_value: "0:00:07:31")

    assert_output("Wrote #{MIS_FILE}\n", "") do
      darkdb1.set()
    end

    darkdb2 = DarkDB.new(mis_path: MIS_FILE, table: "info")

    expected = <<~EOS
    created_by              creator
    last_saved_by              user
    total_time               451000 (string: 0:00:07:31)
    EOS

    assert_output(expected, "File: #{MIS_FILE}\n") { darkdb2.get() }
  end

  def test_parse_int_valid
    darkdb = DarkDB.new
    assert_equal(10, darkdb.parse_int(10))
  end

  def test_parse_int_invalid
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.parse_int("a") }
    assert_equal("Value contains invalid characters.", error.message)
  end

  def test_parse_u32_too_high
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.parse_u32(4_294_967_296) }
    assert_equal("Value too high. Must be 4294967295 or less.", error.message)
  end

  def test_parse_u32_too_low
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.parse_u32(-1) }
    assert_equal("Value too low. Must be 0 or more.", error.message)
  end

  def test_parse_i32_too_high
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.parse_i32(2_147_483_648) }
    assert_equal("Value too high. Must be 2147483647 or less.", error.message)
  end

  def test_parse_i32_too_low
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.parse_i32(-2_147_483_649) }
    assert_equal("Value too low. Must be -2147483648 or more.", error.message)
  end

  def test_read_string_valid
    darkdb = DarkDB.new

    io = StringIO.new(String.new("123456789\x00", encoding: Encoding::ASCII_8BIT), mode: "rb")
    assert_equal("123456789", darkdb.read_string(io, 10))

    io = StringIO.new(String.new("12345\x00\x00\x00\x00\x00", encoding: Encoding::ASCII_8BIT), mode: "rb")
    assert_equal("12345", darkdb.read_string(io, 10))
  end

  def test_read_string_valid_with_null_bytes_in_middle
    darkdb = DarkDB.new
    io = StringIO.new(String.new("12345\x001234", encoding: Encoding::ASCII_8BIT), mode: "rb")
    assert_equal("12345", darkdb.read_string(io, 10))
  end

  def test_read_string_invalid
    darkdb = DarkDB.new
    io = StringIO.new(String.new("123456789\x00", encoding: Encoding::ASCII_8BIT), mode: "rb")
    error = assert_raises(RuntimeError) { darkdb.read_string(io, 9) }
    assert_equal("Invalid string conversion.", error.message)
  end

  def test_pack_string_valid
    darkdb = DarkDB.new
    assert_equal("darkdb\x00\x00\x00\x00", darkdb.pack_string("darkdb", 10))
  end

  def test_pack_string_invalid
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.pack_string("áé", 10) }
    assert_equal("Value contains invalid characters. Must be ASCII characters.", error.message)
  end

  def test_pack_string_too_long
    darkdb = DarkDB.new
    error = assert_raises(RuntimeError) { darkdb.pack_string("12345", 5) }
    assert_equal("Value too long. Must be fewer than 5 characters.", error.message)
  end

  def test_parse_edit_time
    darkdb = DarkDB.new

    assert_equal(darkdb.parse_edit_time("451"), "451")
    assert_equal(darkdb.parse_edit_time("4:51"), "291000")
    assert_equal(darkdb.parse_edit_time("4:51:00"), "17460000")
    assert_equal(darkdb.parse_edit_time("4:05:01:00"), "363660000")

    error = assert_raises(RuntimeError) { darkdb.parse_edit_time("0:60") }
    assert_equal("Time (min, sec) cannot be greater than 59.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_edit_time("60:00") }
    assert_equal("Time (min, sec) cannot be greater than 59.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_edit_time("24:00:00") }
    assert_equal("Time (hour) cannot be greater than 23.", error.message)
  end

  def test_parse_time_segment
    darkdb = DarkDB.new

    assert_equal(darkdb.parse_time_segment(nil), 0)
    assert_equal(darkdb.parse_time_segment("0"), 0)
    assert_equal(darkdb.parse_time_segment("10"), 10)

    error = assert_raises(RuntimeError) { darkdb.parse_time_segment("a") }
    assert_equal("Time contains invalid numbers.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_time_segment("a", :sec) }
    assert_equal("Time (sec) is not a valid number.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_time_segment("a", :min) }
    assert_equal("Time (min) is not a valid number.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_time_segment("a", :hour) }
    assert_equal("Time (hour) is not a valid number.", error.message)
    error = assert_raises(RuntimeError) { darkdb.parse_time_segment("a", :day) }
    assert_equal("Time (day) is not a valid number.", error.message)
  end
end
