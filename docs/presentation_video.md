# TravelTide Rewards Program presentation notes

Video presentation can be found on [youtube](https://youtu.be/mC52mT-WfxE).

## Slide 1 - Title slide
Welcome everyone and thank you for your time.
We started this as a data science project and it turned into story about customer journeys...
So let's 1st get oriented, then we can review our discoveries.

## Slide 2 - Agenda slide
We'll move through this quickly!
- the 1st HALF gets us Aligned
- and the 2nd half gets Interesting.

## Slide 3 - Company & Project Timeline
TravelTide launched in 2021, and the data captured almost everything UNTIL July 2024.
<CLICK for cohort window> 

We focused specifically on ACTIVE users, with 7 OR MORE sessions - since January 2023
That’s was our analytical boundary!

One NOTE before we go further
<CLICK for NOTE>
… all age and date calculations are anchored to August of 2024
The last date in our travel records. 
to ensure all ‘current dates’ were calculated consistently

And an INTERESTING note
<CLICK for AVERAGE DAYS>

EVERY user in the cohort has been on the platform for AROUND 570 days. 
THE Same time window. THE Same opportunity. BUT Very different outcomes.

## Slide 4 - Problem & Scope

Elena came to us with a clear ask 
    stop sending generic emails, 
start sending the right offer to the right person

Five perks. 
Nearly six thousand customers.
One perk per person. No overlaps, no guessing

<CLICK for Constraints>
We set strict rules for ourselves 
cohort definition, minimum activity thresholds, quality data, don't forget the big picture
Not just limitations, quality controls. 

So, what did we find?

## Slide 5 - Data Foundation

50,000 sessions across nearly 6,000 users, FROM the original 12 Million rows
Think of it as building a behavioral fingerprint for every customer on the platform
<CLICK for DOTS >
We started with about 50 data points per person
<CLICK ETL flow > 
Through a process of cleaning, feature engineering, traditional business analytics and ML (to find hidden patterns)
<CLICK for 160 DOTS > 
we expanded that to AROUND 100 and 60 behavioral data points, per user.

<CLICK for anomalies box>
Along the way we found and managed three anomalies 
that would have corrupted our analysis.

I'll touch briefly on that at the end.
Instead of "Garbage in, garbage out"
We CLEANED and Clarified!
- Allowing US to report insights we can validate and stand behind.

## Slide 6 - Who Are Our Customers?

Now for High Level Demographics
- Our core customer is Predominantly female, from Canada or the U.S.
- and 35 to 54 years old ~ that's 63% of the cohort!

AND That age band also happens to generate the highest spend and the highest booking conversion rate.

<CLICK for family status donut>
41% are single with no children - the most flexible travel demographic.
18% are married with kids - potentially very different travel needs
YES, This is a great CONTEXT for everything, 
but no real NEW actionable patterns appeared from Demographics

## Slide 7 - Customer Lifecycle

The biggest and MOST Actionable pattern was highlighted by ML
And THEN fully Validated to reveal a very logical pattern of behavior across the Customer Lifecycle.

And Five distinct GROUPS emerged to tell the story.
<CLICK for TIER 0>
TIER 0: 
~500 customers who signed up ~600 days EARLIER,
browsed, and never booked. Zero revenue. 
But they're still here, still engaging a MIN of 7x over the last 7 months!
That's an opportunity, not a lost cause!
<CLICK for TIER 1>
TIER 1: 
939 customers who took one trip.
Spend $1,344 each.
But look at their cancellation rate | 54.5%. High risk, early stage customer.
<CLICK for TIER 2>
TIER 2: 
1,315 customers | with two trips.
Each spending about $2,595.
Cancel rate drops to 36%. 
<CLICK for TIER 3>
TIER 3: 
2,965 customers | our largest group.
Three to five trips each.
Spend about $4,235 each.
Cancel rate DROPS to 25%.
BY 3-5 trips, these customers are engaged!
<CLICK for TIER 4>
TIER 4: 
257 customers of our most loyal.
AVERAGing Six or more trips each.
Spend ~ $6,410 each.
with Cancellation rate under 18%.
This is what a TravelTide success story looks like...
AND this is where we want EVERYONE - eventually!

Remember! The MAJORITY of these customers 
had about the same 600 days to reach Tier 4 --- but they didn’t…
So That is OUR roadmap to increase revenue.

<Click to reveal revenue projection rows: >

If just 10% of users in each tier moved up one tier
that's a million dollar revenue opportunity.
<CLICK for 2nd tier >
if we can help 10% of users move up Two tiers up (that's from 1 trip to 3 trips)
Nearly $1.8 million increase.
Same customers. | Better incentives.

## Slide 8 - Lifecycle Tier — Detailed Metrics

Here are the numbers behind the story
<CLICK for>
$18.8 million in cohort revenue 
and Tier 3 alone accounts for $12.5 million of that

<CLICK for> Notice the days-to-frist-trip column 
Tier 1 users take 53 days from signup to first booking.  
They are hesitant, limited and reserved.
By Tier 3 that's down to 8 days. 
motivated and engaged
the Tier 4 users where immediate engaged and committed early.
The perk strategies are designed to help more customers overcome obstacles and limits to getting engaged
... and build positive travel history & relationship!

## Slide 9 - Booking & Spending Patterns

<CLICK for the session activity chart: >
Three lines, browse, booking, and cancel sessions.
The pattern is the same every day!
activity builds through the morning,
accelerates after 4pm, peaks around 7pm.
7pm to 8pm is your single highest booking hour with 1,584 bookings. 
That's your prime target time window to keep in mind when scheduling your promotional emails to ensure they are at the TOP of their NEW emails!
<CLICK for stat cards:>
74% of bookings are packages - flight and hotel together. 

<CLICK for discounts:>
AND 73% of bookings use no discount at all.
Take note of that discount number 
I'm coming back to that later when we talk about perks assignment.

## Slide 10 - Flight Travel Patterns

If we dig into Flight travel patterns
we see International flights are 38% of all flight bookings 
but they carry a 49% fare premium over Domestic flights.
International travelers also book (on average) ~22 days in advance 
compared with 11 days AVG lead time for domestic.
An IMPORTANT Note here:
Of ALL Flights (or packages with flights), are booked ranging from: 
1 day in advance to
365 days in advance
BUT
75% of ALL flights that are booked...
<CLICK for: >
are booked around 10 days in advance.
That is Less than 2 weeks before travel.
and around 3% or LESS are booked more than 90 days in Advance!
This combination:  
higher fares,
advance planning,
limited discount usage, and 
premium travel behavior
is exactly the profile that tells us Free Checked Bags is a meaningful offer for this group.
It's not a random, leftover perk. It's matched to demonstrated behavior.

## Slide 11 - Perk Assignment Strategy

We designed 5 perks to match the Customers' Journey 
and meet them where they are NOW
BUT also EVOLVE with them as time goes on.
Five perks. 5,998 users. Zero unassigned. 

#1 EXCLUSIVE DISCOUNTS: 
42% of the cohort, our largest group.
Mostly early-stage users. (never booked < 3 trips).
The Average user here spends $2,332.
The goal is conversion | get them to book, and get them moving up through lifecycle.

#2 NO CHANGE FEES:  
3.9% - small group, high risk.
These are users whose - CANCELLED 40% or more
... of what they originally booked.
The right offer turns cancellations into CHANGES
and protects revenue!

#3 FREE CHECKED BAGS: 
11.9% of users
They are majority international flyers. 
Highest average fare per seat at $433 AND not Discount chasers.
They are Premium travelers who will notice and appreciate a premium offer.

# 4 FREE HOTEL MEALS: 
3.7% of users that make up a unique subset
They are hotel-focused
with high discount dependency on hotel bookings specifically.
A meal perk substitutes meaningfully for the discount behavior they already demonstrate.

... and our highest perk
# 5 PREMIUM TRAVEL BENEFITS:
38% of users AND your most loyal,
highest-spend users.
Average spending is $4,490 each.
Low discount use, low cancellation, high frequency.
They don't need a discount.
They need to feel recognized.

Every PERK assignment is driven by behavior | not demographics | not assumptions.

## Slide 12 - How Perks Are Assigned

Here is how they are assigned!
--- Walk the tier rows quickly---
A "never-booked" user gets Exclusive Discounts 
the acquisition hook.
A single-trip user -- with high cancellation gets No Change Fees. 
otherwise continued Exclusive Discounts
A two-trip user --  
gets Free Checked Bags, No Change Fees
or continued Exclusive Discounts
based on their small number interactions
to encourage booking their next trip and NOT cancelling!
A three-plus trip user -- gets evaluated across all five perks 
based on their actual behavioral signals
all intended to encourage them to book and keep their next travel with TravelTide
<CLICK for teal bar at the bottom: >
As customers grow on the platform, their perk assignment updates. A new user today, starting in the Exclusive Discounts,
can earn Premium Travel Benefits quickly AND automatically.
The actual method for Perk assignment is so simple,  
you can automate perk assignment from the moment a user signs up,
and have it automatically adjust after any travel is completed or cancelled.
If needed, you could even manually pull a customers history and easily assign a perk by hand.
The model follows the customer. Not the other way around.

## Slide 13 - Recommendations & Next Steps

Four recommended actions -- I'll be quick
*** A/B TEST ***: 
This is the most important one.
Over 30 days,
send one email per week,
using 50% of users randomly pulled from all 5 perk assignments
and treat the other 50% as control... business as usual.
Since AVG booking lead time is under two weeks
results can start being evaluated within the first 30 days.
*** LOYALTY PROGRAM***: 
Formalize the customer evolution through the lifecycle.
Make the lifecycle tiers visible to customers.
Give them an added reason to progress and stay
This is an ADD-ON benefit, in addition to the perks.

*** CANCELLATION UX ***: 
Our data shows 75% of cancel sessions exceed one hour
56% hit a 2-hour system timeout.
The cancellation flow isn't closing properly and
potentially a quick IT fix, that reduces noise in the data
and likely improves the customer experience.
*** THRESHOLD REVIEW ***: 
The behavioral rules we built are best reviewed quarterly.
Customer behavior evolves and the behavior model is designed to evolve with it.

## Slide 14 - Final slide

*** "Every customer starts somewhere. 
    The right perk moves them forward."

5,998 users. Every one assigned. Zero left behind. 
- Check!

<CLICK for revenue callout:>
$1.78 million of potential increase 
from the customers you already have,
using behavior they've already shown

<CLICK for CTA bar:>
One simple decision is needed today
and you can watch over the next 30 days.
Send 1 batch of targeted emails every week. 
AND let the data confirm what the analysis predicts.

Thank you. I'm happy to take questions.
