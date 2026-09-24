# Field combat visual review

The current 1v1 screen uses a painted elevated arena and two separate cutouts.
It is readable, but the fighters still behave like flat images: a whole cutout
slides forward, becomes white on contact, then slides back. This weakens the
sense that the fight takes place on the ground shown behind them.

The owner's reference, [ARTDINK's *Lunatic Dawn: Passage of the Book*](https://www.artdink.co.jp/japanese/title/ldpob/),
keeps combat in the same world view as exploration. The actors, surroundings,
status and command windows remain spatially legible. [*Wasteland 3*'s official
gallery](https://www.inxile-entertainment.com/games/wasteland-3) is a modern
reference for matching characters to the arena through camera angle, scale and
ground shadows. [Larian's combat animation notes](https://forums.larian.com/ubbthreads.php?Number=670706&ubb=showthreaded)
describe preserving action flow by connecting movement and strike animation.
These are visual references, not a request to copy their rules or art.

This pass adds layered foot-aligned contact shadows, a short anticipation before a
strike, a faster approach and slower recovery, and a muted hit response. The
same presentation is used after a committed turn; reduced motion still skips
the sequence. The existing sprites have only one pose each, so this improves
grounding and timing but cannot make a standing cutout perform a convincing
blow or bite.

The next art pass should use one consistent camera/light setup per fighter and
draw **idle, attack, hit and retreat** poses sharing the same foot anchor.
Introduce poses for the existing drifter and dog first, then inspect both at
actual game scale before adding more opponents. Keep HP, damage and outcomes
driven by combat authority, never by animation frames.
