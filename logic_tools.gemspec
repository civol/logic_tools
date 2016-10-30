# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logic_tools/version'

Gem::Specification.new do |spec|
  spec.name          = "logic_tools"
  spec.version       = LogicTools::VERSION
  spec.authors       = ["Lovic Gauthier"]
  spec.email         = ["lovic@ariake-nct.ac.jp"]

  spec.summary       = %q{A set of tools for processing logic expressions.}
  spec.description   = %q{LogicTools is a set of command-line tools for processing logic expressions.\n\
The tools include:\n\
 * simplify:  for simplifying a logic expression.\n\
 * std_conj:  for computing the conjunctive normal form of a logic expression.\n\
 * std_dij:   for computing the disjunctive normal form a of logic expression.\n\
 * truth_tbl: for generating the truth table of a logic expression.\n}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  # Expressions are parsed using parslet
  spec.add_dependency "parslet"
end
