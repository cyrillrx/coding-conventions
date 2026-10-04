# 📘 Code Review Comments

How a review comment is written so its intent is clear, and how it is answered. The emoji legend below is for the reviewer; [Responding to a comment](#responding-to-a-comment) is for the author.

> ~~A picture is worth 1,000 words.~~ _An emoji is worth 20 words._

A little bit of emoji can go a long way when it comes to code reviews and make giving and receiving code review a little bit more enjoyable 😃.

Using CREG (Code Review Emoji Guide) puts more ownership on the reviewer to give the reviewee added context and clarity to follow up on code review. 
For example:
* Knowing whether something really requires action (🔧)
* Highlighting nit-picky comments (⛏)
* Flagging out of scope items for follow-up (🕐) 
* Clarifying items that don’t necessarily require action but are worth saying (👍, 📝, 💭)

## Emoji Legend

|          | `:code:`                             | Meaning |
| :------: | :----------------------------------: | --- |
| 👍👌🎉🙏 | `:+1:` `:ok_hand:` `:tada:` `:pray:` | I like this... <br /><br /> ...and I want the author to know it! This is a way to highlight positive parts of a code review. |
| 🔧       | `:wrench:`                           | Mandatory change that impacts the behavior of the code. <br /><br /> I feel this might lead to a bug or crash and I think this needs to be changed. |
| ⛏        | `:pick:`                             | This is a nitpick. <br /><br /> This is a small adjustment I think should be made in order to improve readability, coherence with the codebase or compliance to the guidelines. Might also be an organization suggestion. |
| 💭       | `:thought_balloon:`                  | Let me think out loud here for a minute. <br /><br /> I might express concern, suggest an alternative solution, or walk through the code in my own words to make sure I understand. |
| 🕐       | `:clock1:`                           | The comment may be addressed later. Filing a ticket in the project's tracker, and referencing it in the code, is recommended. |
| 🏕        | `:camping:`                          | Here is an opportunity, not directly related to your changes, for us to leave the campground [code] cleaner than we found it. Most of the time such a cleanup belongs in its own PR — keep it in the current one only when it is a couple of lines in a file that PR already touches. |
| ❓       | `:question:`                         | I have a question. <br /><br /> This should be a fully formed question with sufficient information and context that requires a response. |
| 📝       | `:memo:`                             | This is an explanatory note, fun fact, or relevant commentary that does not require any action. |

## Usage

Prepend comments with the appropriate emoji to convey the meaning associated with it. Combine emoji for added fun.

## Examples:

> 🔧 This method feels overly verbose and I can see can that we can simplify this approach by [...]. I think this should be refactored before we merge this feature and this becomes a permanent pattern in our codebase.

> ⛏ We have an existing helper, `ApiHelper`, that accomplishes this same task. Let's pull it in and replace your implementation with it.

> ⛏🕐 This section of code feels like it could be extracted nicely into a separate module. I feel like that would create clearer boundaries and increase readablity here.

> ⛏ These intermediary variables and if statements could be simplified down to a single ternary expression.

> 👍 Wow, I would never have thought of that myself. Swell work!

> 💭🕐 I've been meaning to explore library X which claims to solve this exact problem. That could be worth exploring and peeking under the hood to see what concerns they are specifically addressing.

> 🕐 We really need to invest some time in refactoring out our use of this deprecated library. _Issue created: [LINK TO ISSUE]_.

## Reading an emoji

The emoji is an **intent** signal: it tells the author what the reviewer expects, and nothing more. It never sets the severity of a finding nor the response it gets — a 🔧 can be factually wrong, a 💭 can uncover a real crash, and a comment with no emoji at all (an external reviewer, a bot) is read the same way. Scoring a finding belongs to [Code Review Triage](code-review-triage.md#7-coming-from-a-review-comment).

## Responding to a comment

Every comment gets a reply before the merge, the declined ones included: a silent thread reads as ignored, not as declined.

Each comment gets one outcome, and its rationale is stated alongside it — to the reviewer in the reply, and in any table proposing the outcomes before they are posted:

| Outcome    | When                                                                                                 |
|------------|------------------------------------------------------------------------------------------------------|
| ✅ Apply   | The comment stands: valid, clear, and consistent with the project's conventions                      |
| 🕐 Defer   | The comment stands, but is too costly or too broad for this PR; it needs an owner and a trace        |
| ⚠️ Discuss | It needs a design decision, is ambiguous, contradicts a convention, or arrives with no stated reason |
| ❌ Skip    | It is factually wrong, out of scope, or already addressed                                            |
| 💬 Answer  | It needs no code change: a note, a compliment, or a question that an answer settles                  |

A request whose reason is missing is ⚠️ **Discuss**, never ❌ **Skip**: ask for the reason, then decide on the answer. A reason need not be a link — a team convention, a precedent already in the codebase, or a stated line of reasoning all count. Backing a comment is the reviewer's duty ([Git & Collaboration §7](git-and-collaboration.md#reviewers)); it is not the price of being heard.

How the code is decided — severity, impact, complexity, and when a 🕐 is the right call — belongs to [Code Review Triage](code-review-triage.md). A 🕐 is never reported as applied: its owner and its trace follow [§6 of that document](code-review-triage.md#6-follow-ups).

**Reply tone per outcome:**

- ✅ **Apply**: briefly confirm what changed ("Fixed — renamed `X` to `Y`.").
- 🕐 **Defer**: agree, say it is not done here, and name the trace ("Agreed, but out of this PR's scope — tracked in #142."). Never phrase it as fixed.
- ⚠️ **Discuss**: ask for the missing decision, clarification, or reason.
- ❌ **Skip**: explain concisely why the comment is declined, citing the conventions or sources that apply.
- 💬 **Answer**: answer the question, or acknowledge the note.

**Resolving threads:** resolve only what was addressed or acknowledged — the ✅ threads, and the 💬 threads that ask nothing back. A 🕐 thread stays open, since it is the trace of the deferral; ⚠️, ❌ and an answered question stay open for the reviewer to follow up.

### Credits

This is inspired by this repository with little adaptations to meet our team needs.

* https://github.com/axolo-co/code-review-emoji-guide
