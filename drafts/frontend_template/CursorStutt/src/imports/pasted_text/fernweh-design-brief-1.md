# FERNWEH — design brief

> Direction for generating the UI. It says what each part of the product has to *achieve* and what it should feel like. It deliberately does not specify layouts — that's the generator's job.

---

## What we're making

Someone picks a city they want to spend a day in. A voice-agent film director scouts it for them and builds a shooting schedule — a route of locations worth filming, in an order that works on foot.

If they turn incentives on, the route bends. It now favours places and brands that have posted an open invitation with something attached: a free drink, a meal, entry, a night's stay, sometimes a fee. Those stops pay.

At each stop the director walks them through a handful of shots and interviews them after each one. What they say out loud becomes the voiceover of a video that edits and publishes itself. They show the finished video to claim what was promised, and walk to the next location.

**The incentive is a reason to route through a place, not a reward for having been there.** That's the shape of the product and everything below follows from it.

Two surfaces: a mobile app for the creator (this is the build), and a desktop tool for the places posting invitations (designed, not built — it exists for the pitch).

## The two modes, and why the toggle matters

With incentives **off**, this is a travel filmmaking app: a director takes you around a city you don't know and you leave with a film of your day. Useful on its own, to someone who has never heard of a brand deal.

With incentives **on**, the same day pays for itself.

The toggle should visibly redraw the route — the schedule re-plans in front of the creator, some locations swapped for ones that are paying. That single interaction is the clearest possible explanation of the business model, to a creator and to a judge, and it should be treated as a designed moment rather than a settings switch.

**Non-paying stops are content, not filler.** The director routes past a viewpoint or an old town square because it belongs in the film, and no business is involved. Keeping them in is what makes the toggle mean something, and it's what stops the product from feeling like a run of errands for brands.

## Who is holding the phone

Someone in their twenties with a rail pass and a free Saturday. Under 5k followers, so no marketplace will list them and no brand will pay them. They already go places. They already take sixty photos and post none of them.

Two distinct headspaces, and the app has to serve both:

- **Planning.** At home, on the train, the night before. Choosing a city, seeing what a day there could be, deciding if it's worth going. This is where the product earns its name.
- **Doing.** On the street between stops, one hand free, on 4G, in daylight. Following the schedule, and nervous about talking to a phone in a room full of people.

Expansive when planning, tunnel-visioned when doing. Same app, two moods.

## The core idea: it's a production, not a social app

The creator is not a user with a to-do list. They've been hired for the day. The director scouts locations, issues a schedule, briefs each setup, and calls the wrap.

Borrow the vocabulary and the structure honestly: locations rather than places, a schedule rather than an itinerary, setups rather than tasks, second takes rather than errors, a wrap rather than a success state, a printed shot when the director approves one.

This exists to solve one specific thing. Research says the barrier was never filming — it was everything after filming, plus the fear of looking foolish while doing it. We removed the editing entirely. The production framing removes the rest: on a shoot, talking to camera is *the job*, and nobody feels stupid doing their job.

## The signature: the app is colour-graded by your director

The one thing to be bold about. Everything else stays quiet.

Planning is chromatically neutral — warm graphite and bone, the day doesn't belong to anyone yet. Choosing a director for the day grades the entire interface: accent, surface tint, the route line on the map, the guides drawn over the camera, the grain, the easing curve. One tap, one shared transition, everything moves together.

- **Kubrick** — cold, exact, symmetrical. Blue. Mechanical motion.
- **Wes Anderson** — warm, flat, pastel, slightly toy-like. Rose. A little bounce.
- **Doku / Tatort** — desaturated, grainy, handheld, unglamorous German television. Bone.
- **Viral** — high contrast, acid, fast. Lime. Snappy.

The choice already drives the shot lists, the director's voice, and how the video renders — and it should plausibly shape which locations he picks. Making the interface the fifth thing it drives means one tap visibly changes the whole day.

## The moments that have to land

**Choosing a city.** The front door, and the thing the name promises. It should feel like standing over a map deciding where to go, not like filling in a search field. What a person needs to weigh: what's there, how far it is, and whether anything is paying.

**Getting the schedule.** The director comes back with a plan for the day, and it has to be immediately readable as a plan: a route across the city, the stops in order, how long each takes, how far apart they are, and — with incentives on — what the day is worth in total. That total is the number that decides whether someone actually goes, so it should be impossible to miss without being the loudest thing on screen.

The schedule should feel authored, not generated. The director explains his choices in a sentence or two. Every stop needs a reason for existing.

**Turning incentives on.** The route redraws. Show the change rather than just applying it.

**Committing to the day.** Where a plan becomes a production and the grade lands. It should feel like accepting a job.

**Moving between locations.** The between-stops state, which is where the creator actually spends most of the day and which no travel app designs properly. What matters: which stop is next, how far, whether they're on schedule, and what they're walking into. This is also where the director should be a companion rather than a taskmaster — light, occasional, never nagging.

**Being told where to stand.** At a stop, the framing instruction is drawn *over the camera* in the chosen director's visual language, not written underneath as a caption. Centre lines and vanishing points for Kubrick, a flat grid for Wes, an off-kilter handheld frame for Doku, caption safe-zones for Viral. No camera app does this, and it's the clearest possible answer to "I don't know what I'm doing."

**Talking out loud.** After each capture the director asks what they thought. This is the product — their spoken answer becomes the narration — so it must feel like the reward for the shot, not a toll gate after it. The question arrives immediately, over the frame they just took. Their voice should be visibly received: something on screen responds to them speaking.

The director has no face. He's a voice, a reactive waveform, and his lines as film subtitles. An animated avatar is expensive to make non-creepy and reads cheaper than restraint does.

**Getting paid, at the stop.** For goods, the creator holds their phone up to a staff member who has never seen this app, in a loud room, at arm's length, in bad light. Design it for *that person's* eyes: what's owed, which place's invitation it belongs to, and one obvious tap that plays the video. No QR code — the verification is a human watching the video. For a fee, the same card states the amount and that it's on its way.

**The day's cut.** At the end, the stops assemble into one film of the city. This is the emotional payoff and the thing that gets posted, and it's what separates this from a chore app: they didn't run errands for four brands, they made something about a day.

## One film per stop, and one for the day

This tension needs settling deliberately, because it decides the whole flow.

Each stop produces its own short video, finished on the spot. It has to — that video *is* the receipt, and the creator can't claim a drink against a film that won't exist until four hours later.

The day's cut is assembled from those stops at the end. It's the reason to finish the route rather than stopping after the free coffee, and it should be visibly accruing all day: a strip of finished stops that fills as they go, so abandoning halfway feels like leaving something incomplete.

## Plans break

The route is a plan and plans fail. Someone sleeps in, a place is shut, they skip a stop, they linger somewhere for two hours, they wander off the route entirely.

The director re-plans without drama and without guilt-tripping. No red warnings, no "you're behind schedule." A production reshuffles the day and moves on. Designing this well is what makes it feel like a competent collaborator rather than a checklist that's disappointed in you.

## Incentives are a spectrum, not a coupon

A drink, a meal, entry, a night's stay, a fee. Someone weighing up a train ticket needs to sort by what a day is worth, so the difference has to be legible instantly — and whatever visual weight system you use has to hold a free coffee and a paid brand campaign in the same list without either looking silly.

Never call it a reward, a coupon or a deal. It's a fee, and the creator is being hired.

## Gamification

Only the kind that comes from the film world. Second takes, printed shots, a wrap time, a set of four directors collected by shooting with each. Cities and locations accumulate as a filmography rather than a checklist — that's the version that fits a travel product, and it's the only leaderboard-shaped thing worth having.

No points, no XP, no streaks, no levels. There are no accounts to hang them on and they'd break the tone completely.

## The other side (designed, not built)

Static screens for the pitch, because otherwise "who's posting these invitations?" has no picture attached.

Light, calm, desktop, no director grade — someone at a laptop at eleven in the morning. The opposite of the creator app.

**Posting an invitation** should feel like writing a job posting, not filling in a form: where, what the place is like, what should be in the video, what's on offer, when it's valid. The line carrying the business case sits under the button — *you only pay once a video exists*.

**Seeing what came back** shows something a venue can never get today: a deliverable. Finished videos, each titled with the creator's own spoken sentence, each showing whether the incentive was claimed. Roadmap items — creator authenticity score, tiered offers, location verification — can appear greyed with a "coming" label. Showing them honestly pre-answers the most likely question in the room.

## Palette and type direction

The shoot side is dark because it's mostly a camera, but not black — the warm brown-black of film base, so thumbnails and skin tones don't go sour. Bone rather than white for text. Hairline dividers rather than grey borders. Red means recording, green means a printed take; every other colour comes from the active grade. Film grain is the only texture. No gradients, no glass, no glow.

The map carries more weight now and needs real attention. Dark enough to belong to the same app, but legible as geography. Suppress everything that isn't relevant — roads, labels, borders all recede — so the route and its stops are the only lit things on it. A city should look like a dark field with a line drawn through a handful of bright windows. Paying and non-paying stops must be distinguishable at a glance without turning the map into a legend.

Three type roles: a characterful display face with a width axis for headlines, a monospace used uppercase and widely tracked for anything that's a number, a distance or a state, and a plain sans for instructions and body copy. The mono is doing most of the work of making this look designed rather than generated. Do not use Inter for the body face.

## Voice

**English by default, with German one tap away.** Every string exists in both, and the switch is reachable from the first screen — not in a settings screen, because there isn't one. A small mono toggle that looks like a set-report field rather than a UI control.

Two things it has to do properly:

- The choice sticks and follows the day. Switch mid-shoot and location names, instructions and transcript labels all change with it.
- **It also sets the director's language.** He speaks whatever the interface is set to and mirrors the creator from there. An English interface with a German voice in your ear is the kind of seam that makes a demo feel unfinished — and it's the only place this toggle reaches outside the UI.

Place-supplied text — venue names, briefs, what's on offer — stays in whatever language the business wrote it. Don't machine-translate a café's own words.

Sentence case, plain verbs, no exclamation marks, no emoji. Errors say what happened and what happens next, in the app's voice, and never apologise. Empty and waiting states give direction rather than mood.

The app never says *AI*, *generated*, or *prompt*. The creator is on a shoot; sets don't talk about their tooling. Say all of that in the pitch, never in the product.

## Never

- An editing surface of any kind — no timeline, no trim, no filter picker. The entire value proposition is that it doesn't exist.
- An onboarding carousel or tutorial. The director is the tutorial.
- A settings screen, a dark mode toggle, a profile page.
- A face for the director.
- Follower counts, reach estimates, or anything ranking creators by audience. The product exists specifically for people no marketplace will list.
- Progress guilt — no red "behind schedule", no broken streaks, no pressure to finish the route.
- Purple or indigo accents, glowing edges, gradient backgrounds — the default look of every AI demo.
- A QR code at the counter.

If something on this list starts to feel necessary while building, it isn't. It's a roadmap slide.