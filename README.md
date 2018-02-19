# GDAX Notifier

This app polls GDAX and hits a webhook whenever an order has been filled. I currently use IFTTT Maker to send iOS push notifications.

![Notification Screenshot](/images/notification.jpg?raw=true "What iOS Notifications Look Like")

## Create Maker Webhook

Create an IFTTT account and set up a new maker webhook
https://ifttt.com/maker\_webhooks and set it up to point at something (like app notifications):

![IFTTT Screenshot](/images/ifttt.png?raw=true "What IFTTT Looks Like")

Set the notification equal to:

```
GDAX {{Value1}} {{Value2}}: {{Value3}}
```

## Configure

Set in your environment:

```
GDAX_API_KEY=
GDAX_API_SECRET=
GDAX_API_PASS=
MAKER_EVENT=
MAKER_KEY=
```

Find the `MAKER_KEY` from the https://ifttt.com/maker_webhooks page and click
on the "Documentation" button.

## Run

```
bundle exec ruby run.rb
```

Run under your process manager of choice.
