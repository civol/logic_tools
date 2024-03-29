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
  spec.description   = %Q{LogicTools is a set of command-line tools for processing logic expressions. 
The tools include: 
simplify_qm for simplifying a logic expression, 
simplify_es for simplifying a logic expression much more quickly than simplify_qm, 
std_conj for computing the conjunctive normal form of a logic expression, 
std_dij for computing the disjunctive normal form a of logic expression, 
truth_tbl for generating the truth table of a logic expression,
is_tautology for checking if a logic expression is a tautology or not,
and complement for computing the complement of a logic expression.}
  spec.homepage      = "https://github.com/civol"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]



  spec.add_development_dependency "bundler", ">= 2.2.10"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest", "~> 5.0"

  # Expressions are parsed using parslet
  spec.add_dependency "parslet"
end
