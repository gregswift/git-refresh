# Style

How code in this repository is written. `CONTRIBUTING.md` covers how to build,
test and submit it.

## Comments

Comments say why. The code says what.

Say what is necessary in as few words as it takes. A comment that needs a
paragraph is usually not a comment: it is a commit message, or a section of
WORKFLOWS.md, and it belongs there instead.

- **Delete a comment that adds nothing.** One that names the code below it,
  repeats a nearby `printf`, or points at something already visible.
- **Keep a comment that carries what the code cannot.** A constraint from
  elsewhere, a git command that does not do what it reads like, an approach that
  fails, a measurement that explains an odd bound.
- **Say what the code does, then why.**
- **Cut a closer that names no cost.** "What that costs depends on your
  configuration" does no work.
- **Answer the question the comment raises.** Where it explains a condition, say
  what happens when the condition is false.

Write plainly: one idea per sentence, twenty words or fewer, active voice,
present tense, the same word for the same thing, no figures of speech. If three
sentences are not enough, the explanation belongs somewhere else.

File headers say what the script is for. Function headers give the contract.
Section banners are navigation.
