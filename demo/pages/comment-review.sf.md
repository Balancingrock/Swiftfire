---
layout: page
title: Review Comments for Approval
menuInclude: yes
menuTopTitle: Admin
menuSubTitle: Review comments for approval
---
<style>
input { color: black; }
textarea { color: black; }
p { margin: 0; }
</style>

.if($account, nil)
	.assign(illegal, true)
.else()
	.if($account.is-moderator, true)
		.assign(illegal, false)
	.else()
		.if($account.is-domain-admin, true)
			.assign(illegal, false)
		.else()
			.assign(illegal, true)
		.end()
	.end()
.end()

.if($info.illegal, true)
<div style="width: 100%;">
	<p>Insufficient acces rights, please <a href="/pages/login.sf.html">login</a> with an administrator or moderator account</p>
</div>

.else()
	.setup(first-comment-to-approve)
<div style="width: 100%; display: flex; flex-direction: column;">

	.if($info.none, true)
	<div style="width: 100%;">
		<p>There are no comments waiting for approval</p><br>
	</div>

	.else()
	<div>
		<p style="display: block; margin-bottom: 1em;">Comment by: .show($info.dname)</p>
	</div>
	<form method="post" action="/command/comment-review">
		<input type="hidden" name="account-name" value=".show($account.name)">
		<input type="hidden" name="comment-uuid" value=".show($info.uuid)">
		<input type="hidden" name="comment-section-identifier" value=".show($info.csid)">
		<input type="hidden" name="next-url" value="/pages/comment-review.sf.html">
		<input type="hidden" name="comment-original-timestamp" value=".show($info.timp)">
		<div style="width: 100%; display: flex; flex-direction: column;">
			<div style="width: 100%; margin-left: auto; margin-right: auto; border: 1px solid lightgrey;">
				<p style="display: block; width:100%; margin: 0; padding: 0;" disabled>.show($info.html)</p>
			</div>
			<div style="width: 100%; display: flex; flex-direction: row; align-items: baseline; justify-content: space-between; margin-top: 1em;">
				<p style="display: block; margin-bottom: 1em; color: grey;">Note: 'Reject' is final.</p>
				<div style="display: flex; flex-direction: row; align-items: baseline; justify-content: flex-end;">
					<input type="submit" name="button" value="Accept" style="margin-right: 1em">
					<input type="submit" name="button" value="Reject" style="color: red; margin-right: 1em">
					<input type="button" name="button" value="Show Article" formaction=".show($info.original-url)" formtarget="_blank">
		 		</div>
			</div>
		</div>
		<div style="width: 100%; display: flex; flex-direction: column; margin-top: 2em;">
			<p style="display: block; margin-bottom: 1em;">The original text may be modified below:</p>
			<textarea style="max-width:100%; min-width:100%; height:200px; border: 1px solid lightgrey; box-sizing: border-box;" name="comment-text">.show($info.orig)</textarea>
			<div style="width: 100%; display: flex; flex-direction: row; align-items: baseline; justify-content: space-between;">
				<p style="display: block; margin-bottom: 1em; color: grey;">Note: 'Preview' updates the original comment.</p>
				<div style="display: flex; flex-direction: row; align-items: baseline; justify-content: flex-end; margin-top: 1em;">
					<input type="submit" name="button" value="Preview" style="margin-right: 1em">
					<input type="submit" name="button" value="Update and Accept">
				</div>
			</div>
		</div>
	</form>
	.end(if-else-info-none)

</div>
.end(if-illegal)