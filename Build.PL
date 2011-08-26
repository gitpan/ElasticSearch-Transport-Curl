
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.38"
  },
  "dist_abstract" => "A libcurl based HTTP backend for ElasticSearch",
  "dist_author" => [
    "Clinton Gormley <drtech\@cpan.org>"
  ],
  "dist_name" => "ElasticSearch-Transport-Curl",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "ElasticSearch::Transport::Curl",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "ElasticSearch" => "0.41",
    "ElasticSearch::Transport" => 0,
    "Encode" => 0,
    "WWW::Curl::Easy" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
