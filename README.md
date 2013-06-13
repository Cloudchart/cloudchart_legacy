# [CloudChart](http://cchrt.me)

CloudChart is a web app that is built on Rails and MongoDB.

## Installation

- Install system packages: ```brew install imagemagick mongodb redis elasticsearch graphviz qt```
- Make sure mongodb/redis/elasticsearch are running on current (default) configuration:

```
mongodb:
	database name: cloudchart
	host: localhost
	port: 27017

redis:
	namespace: cloudchart
	host: localhost
	port: 6379

elasticsearch:
	host: localhost
	port: 9200
```

- Install Ruby ([rvm](http://rvm.io) is preferred, see ```.ruby-version``` for latest version)
- Create gemset: ```rvm gemset create cloudchart```
- Gems, of course: ```bundle```
- Use [pow](http://pow.cx/) or just run it as ```rails server```.

## Testing

Just run ```rspec -fd```.

Please use [Rspec](https://github.com/rspec/rspec) and [Capybara](https://github.com/jnicklas/capybara) to cover UX features and cases.

## Contributing

We use [successful git branching model](http://nvie.com/posts/a-successful-git-branching-model/) (also known as [git-flow](https://github.com/nvie/gitflow)).

PRs are welcome.
