# [CloudChart](http://cchrt.me)

CloudChart is a web app that is built on Rails and MongoDB.

## Installation

1. Install system packages: ```brew install imagemagick mongodb redis elasticsearch graphviz```
1. Install Ruby ([rvm](http://rvm.io) is preferred, see ```.ruby-version``` for latest version)
1. Create gemset: ```rvm gemset create cloudchart```
1. Gems, of course: ```bundle```
1. Use [pow](http://pow.cx/) or just run it as ```rails server```.

## Testing

Just run ```rspec -fd```.

Please use [Rspec](https://github.com/rspec/rspec) and [Capybara](https://github.com/jnicklas/capybara) to cover UX features and cases.

## Contributing

We use [successful git branching model](http://nvie.com/posts/a-successful-git-branching-model/) (also known as [git-flow](https://github.com/nvie/gitflow)).

PRs are welcome.
