const functions = require("firebase-functions");
const stripe = require("stripe")(functions.config().stripe.api_key);

exports.createStripeAccount = functions.https.onCall(async (data, context) => {
  try {
    const account = await stripe.accounts.create({
      type: "express",
      country: "US",
      email: data.email,
      capabilities: {
        card_payments: {requested: true},
        transfers: {requested: true},
      },
    });

    return {accountId: account.id};
  } catch (error) {
    console.error("Error creating Stripe Connect account:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Unable to create Stripe Connect account",
    );
  }
});

exports.createAccountLink = functions.https.onCall(async (data, context) => {
  try {
    const accountLink = await stripe.accountLinks.create({
      account: data.accountId,
      refresh_url: "https://yourdomain.com/reauth",
      return_url: "https://yourdomain.com/return",
      type: "account_onboarding",
    });

    return {url: accountLink.url};
  } catch (error) {
    console.error("Error creating account link:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Unable to create account link",
    );
  }
});

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  console.log("Received data:", data);
  const {amount, currency, onBehalfOf} = data;

  if (!amount || !currency || !onBehalfOf) {
    console.log("Missing parameters:", {amount, currency, onBehalfOf});
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Required fields 'amount', 'currency', and 'onBehalfOf' are missing.",
    );
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      application_fee_amount: Math.round(amount * 0.01),
      transfer_data: {
        destination: onBehalfOf,
      },
      on_behalf_of: onBehalfOf,
    });

    return {
      result: {
        client_secret: paymentIntent.client_secret,
      },
    };
  } catch (error) {
    console.error("Error creating PaymentIntent:", error);
    throw new functions.https.HttpsError(
        "internal",
        "An error occurred while creating the PaymentIntent: " + error.message,
    );
  }
});
