#!/usr/bin/env ruby

require_relative 'lib/notifier'

Notifier.poll(frequency: 10)
