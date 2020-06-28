# Inspecting The Web With Rack

##  Objectives

1. Explain the mechanics of Rack 
2. Create a basic web app 
3. Set up an HTTP web server using a `config.ru` file and the `rackup` command

## Why Rack? 

How does a web server work?

We open a browser (or, these days, an "app") and it uses HTTP to connect to a
remote server. Servers are just code. But somehow when you say
`/search?item=shoes&size=13M` it knows how to find some more code that knows
how to search (in this case, for shoes of size 13M).

All web servers have a core architecture in common. By looking at it, we can
build a mental model for how all web servers work. In the same way, we can
explain how all cars work by:

>  Explosions made by gasoline and fire make an inside wheel go round and that
>  inside wheel makes the outside wheels go round"

In the same way, we can say that all web servers:

> They look at an HTTP request and look at the HTTP verb and path and then run
> some conditional logic to find out which stuff to send back

In Ruby, this idea of "a common foundation for all web-server like things" is
captured in a gem called [Rack](https://rack.github.io/). Rails "rides on top
of" Rack. Sinatra "rides on top of" Rack. In fact, the idea of a base, common
web-server library was such a good idea, other languages like Python and
Node.JS implemented their own "base" web server.

Before we get to the complexity of things built on top of Rack, let's get a
simple server working on Rack.

## Setting up Rack

To work with Rack, we need to create a thing that responds to a single method:
`#call`. Often, this will be a new class. However, new instances of the
[`Proc`][proc] class are run by calling `call` on them, so one could simply use
a `Proc`.

All this method needs to do is return an `Array` with three elements:

* An [HTTP Status code][http-status] where `200` is used for `OK`
* A `Hash` with a `"Content-Type"` key that returns the value (for HTML-based
  documents) of `text/html`
* Something that responds to `each` which contains the multiple lines of a
  document of the `"Content-Type"`'s type (here, `String`s that look like HTML:
  `"<p>Like this!</p>"`. The most common "each-able" thing is an `Array`

Here's a sample that returns HTML:

```ruby
[200, {"Content-Type" => "text/html"}, ["Hello <em>World</em>!"]]
```

```ruby
[200, {"Content-Type" => "plain/text"}, ["Hello World!"]]
```

In real life, we tend to read HTML content from a file...

```ruby
html_from_file = File.open("my_html.html").readlines
[200, {"Content-Type" => "plain/text"}, html_from_file]
```

## Creating a Rack-Based Web Server

Using this, let's create a basic web app. Follow along with the below instructions. 

Let's create a file called `first.ru`. Files that are used by Rack end with
`.ru` instead of `.rb` because they're normally loaded with a command called
`rackup`. It's a way to say "Hey this is a server definition" to anyone
casually using `ls` in the directory.

```ruby
require 'rack'

# Instances of Proc automatically have a call method that runs the block that
# they're initialized with.
my_server = Proc.new do
  [200, { 'Content-Type' => 'text/html' }, ['<em>Hello</em>']]
end

run my_server
```

Run this code by executing, from the command line:

```shell
$ rackup first.ru
```

Rack will print out something like:

```text
[2019-10-28 12:04:12] INFO  WEBrick 1.4.2
[2019-10-28 12:04:12] INFO  ruby 2.6.3 (2019-04-16) [x86_64-darwin17]
[2019-10-28 12:04:12] INFO  WEBrick::HTTPServer#start: pid=5567 port=9292
```

>Note: If you're using the Learn IDE, you won't be able to get to your website
>with `localhost`. Instead, you'll see a line that looks something like this -
>`Starting server on 159.203.101.28:30001`. To see the webpage, just go to
>`159.203.101.28:30001` in your web browser. Anywhere these instructions tell
>you to go to `localhost`, replace that with this IP address instead!

Let's deconstruct this URL a little bit though. The URL is
`http://localhost:9292/`. The protocol is `http`. That makes sense, but the
domain is `localhost:9292`. What's going on there? `localhost` is normally where
a server like `google.com` goes. In this case, since you are running the server
on your computer, `localhost` is the server name of your own computer. Nobody
else can get that URL though. That's good for right now. This allows you to play
around with writing websites without the security concerns of opening it up to
the entire web. The last part of that URL is the `:9292` section. This the "port
number" of your server. Don't worry too much about this, but you may want to run
multiple servers on one computer and having different ports allows them to be
running simultaneously without conflicting.

The resource that you are requesting is `/`. This is effectively like saying the
home or default.  If you're doing local development, you should be able to go to
`http://localhost:9292/` and see _Hello_ printed out by your web server!

Feel free to change `first.ru` to add changes to your web server. If you make
changes to `first.ru` ***you'll have to shut down the server (Control-C) and
re-start it to see the changes***.

Interestingly, we can swap out the simple `Proc` for a _class_. So long as it
responds to `#call`, Rack will let us make a substitution.

Create a new file called `second.ru` and fill it out like:

```ruby
require 'rack'

# Something that responds to call, that's what Rack demands
class MyServer
  def call(env)
    return [ 200, {'Content-Type' => 'text/html'}, pretty_response ]
  end

  def pretty_response
    (Time.now.to_i % 2).zero? ?  ["<em>Hello</em>"] : ["<strong>Hello</strong>"]
  end
end

run MyServer.new
```

Start it up with: `rackup second.ru`. Visit the web page and hit refresh
several times. When the present time, as an `Integer`, is even, the output is
emphatic; when odd, it's strong.

It's not too far of a step from this "conditional" logic to realize that if a
web server knew what was after the `/` in the URL path, it could make
decisions, run logic, etc... and change what's displayed in response to what's in
the URL. That's basically what web servers do all day long. Rails, Sinatra, any
web programming framework is a way to organize the code that fills out that
third `Array` element in our Rack responses. Amazing!

We could make things look a bit more like a web server by taking our server
code out of the `rackup` file and put it into a class file. We could create:

`my_server.rb`
```ruby
class MyServer
  def call(env)
    return [ 200, {'Content-Type' => 'text/html'}, pretty_response ]
  end

  def pretty_response
    (Time.now.to_i % 2).zero? ?  ["<em>Hello</em>"] : ["<strong>Hello</strong>"]
  end
end
```

And create a new `rackup` file: `third.ru`

```ruby
require_relative './my_server'
run MyServer.new
```

Now we're honoring the way most Rack applications are built: the server setup
code lives in the `rackup` file and our application logic lives in a class
that's referenced by the `run` command in the `rackup` file.

[proc]: https://docs.ruby-lang.org/en/2.0.0/Proc.html
[http-status]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
