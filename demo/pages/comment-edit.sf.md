---
layout: page
title: Edit Comment
menuInclude: no
---
<style>
p { margin: 0; display: block; }
input { color: black; }
textarea { color: black; box-sizing: border-box; max-width: 100%; min-width: 100%; height: 150px; margin-bottom: 1em; }
.comment-input {
	border-top: 1px solid #dddddd;
	width: 100%;
	padding-top: 1em;
}
.input-form {
	display: flex;
	flex-direction: column;
}
.input-form-button {
	margin-top: 1em;
	
}
.details-text {
	margin: 1em 0 1em 0;
	padding: .5em;
	background-color: #f5f5f5;
	font-size: .9em;
}
.small-grey {
	color: grey;
	font-size: .8em;
}
.preview {
	margin: 2em 0 1em 0;
}
.remove-button {
	margin-top: 2em;
}
</style>

<div class="comment-input">
	<form class="input-form" method="post">
		<textarea name="comment-text">.show($request.comment-text)</textarea>
		<p class="small-grey">Use [i]..[/i] for italic, [b]..[/b] for bold. Links will not be clickable.</p>
		<input type="hidden" name="next-url" value=".show($request.next-url)">
		<input type="hidden" name="comment-section-identifier" value=".show($request.comment-section-identifier)">
		<input type="hidden" name="comment-account-id" value=".show($request.comment-account-id)">
		<input type="hidden" name="comment-original-timestamp" value=".show($request.comment-original-timestamp)">
		<input class="input-form-button" formaction="/command/update-comment" type="submit" value="Submit">
		<input class="input-form-button" formaction="/command/edit-comment" type="submit" value="Update Preview">
		<input class="input-form-button" formaction="/command/cancel-update-comment" type="submit" value="Cancel">
		<p class="small-grey remove-button">Remove is final.</p>
		<input class="input-form-button" formAction="/command/remove-comment" style="color:red;" type="submit" value="Remove" >

	</form>
</div>
<div>
	<div class="preview">Preview:</div>
	<div class="details-text"><p>.show($request.preview)</p></div>
</div>