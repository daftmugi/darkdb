#!/usr/bin/env ruby

Dir.chdir(File.expand_path("..", __FILE__))

load "../bin/darkdb"

$0 = "darkdb"
qdb = DarkDB.new
template = File.read("README.template.md")

quest_db_usage = qdb.usage.lines[2..].join("").chomp()

usage = "```\n#{quest_db_usage}\n```"

template.sub!("`USAGE_BLOCK`", usage)

puts(template)
