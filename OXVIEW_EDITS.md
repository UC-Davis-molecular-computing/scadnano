I want to enhance the oxView integration. Please look at app.dart, middleware/oxview_update_view.dart, and view/oxview.dart.

# Overview

Currently any edit made to the design (instance of DesignChangingAction) triggers the middleware to send a http POST message to the oxView instance running in the iFrame.

We want to start building tighter integration. In particular, any edits made in oxView to the design are not propagated back to scadnano. Also, the instant an edit is made it scadnano, it would overwrite any edits made in oxView since it just re-exports the whole design and sends it.

This is going to be tricky, but roughly the idea is to send messages two ways, and for them, rather than having an entire exported design, describe what edit was made so that the other program can update the current design.

I will describe concrete tasks below, iteratively editing this file as we make progress.

# Task 1: two-way message-passing

The first thing I need is a way to send messages from oxView back to scadnano. Hopefully this can also be done using http messages, but I don't know how to set up a listener. However, we've done something similar before, in middleware/autostaple_and_autobreak.dart, which communicated with another server using http.

Note that we send messages to oxView currently using frame.contentWindow.postMessage, which (I think) is sending a message through the browser rather than over the internet. We'd want to do the same thing to send messages from oxView back to scadnano. I think this would be done using window.parent.postMessage from within oxView. The main thing I need is to understand how to listen for such messages and respond to them in Dart. Let's start with that. Specifically, let's assume oxView has deleted a strand and sent a message indicating which strand was deleted (by giving its index). Then I'd want to edit the scadnano design to also delete that strand, in the standard way by dispatching an action. (In this case I think we'd need a new action, since currently the only way to delete strands is with the DeleteAllSelected action, but we don't want to use that, since the scadnano user may have other strands selected than the one(s) that were deleted in oxView).