# heroku-kafka-demo-ruby

A simple heroku app that demonstrates using Kafka in ruby.
This demo app accepts HTTP POST requests and writes them to a topic, and has a simple page that shows the last 10 messages produced to that topic.

You'll need to [provision](#provisioning) the app.

## Provisioning

The easiest way to provision an instance of this drain is to click the following
button.  That will provision a new Kafka cluster, then provision a new drain
that points at it, protected by a randomly generated password.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/heroku-kafka-demo-ruby)

Alternatively you can set it up manually:

Install the kafka cli plugin:

```
$ heroku plugins:install heroku-kafka
```

Create a heroku app with Kafka attached:

```
$ heroku create
$ heroku addons:create heroku-kafka:beta-dev
$ heroku kafka:wait
```

Create the sample topic. For the purposes of this demo, it works best if you have just a single partition, but production apps can and should use more partitions:

```
$ heroku kafka:create messages --partitions 1
```

Deploy to Heroku and open the app:

```
$ git push heroku master
$ heroku open
```
