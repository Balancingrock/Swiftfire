---
layout: page
title: Review Comments for Approval
menuInclude: yes
menuTopTitle: Admin
menuSubTitle: Review comments for approval
---
{::comment}
Only the domain admin or moderators are allowed to see/use this page.
{:/comment}

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
	<p>Insufficient acces rights, please login with an administrator or moderator account</p>
</div>

.else()
<div style="width: 100%; display: flex; flex-direction: column;">
	<div>
		<p>Comments for approval:</p>
	</div>
	
.if($domain.comments-for-approval-count, equal, 0)
	<div style="width: 100%;">
		<p>There are no comments waiting for approval</p><br>
	</div>

.else()
	<div style="width: 100%; display: flex; flex-direction: column;">

	.for(comments-for-approval)
		<div style="width: 100%; display: flex; flex-direction: column;">
			<form method="post">
				<input type="hidden" name="comment-account" value=".show($account.name)">
				<input type="hidden" name="comment-id" value=".show($info.comment-id)">
				<div style="width: 90%; height: 200px; margin-left: auto; margin-right: auto;">
					<p>.show($info.comment-html)</p>
	 			</div>
	 			<div style="width: 100%; display: flex; flex-direction: row;">

		.if($account.name, not-equal, Anon)
					<div class="approval-comment-name">
						<p>Name: .show($account.name)</p>
					</div>
		.else()
					<div class="approval-comment-name">
						<p>Name: Anon-.show($info.dname)</p>
					</div>
		.end()
					<div class="approval-comment-remove">
						<input type="submit" value="Remove" formaction="/command/comment-remove">
					</div>
					<div class="approval-comment-edit">
						<input type="submit" value="Edit"  formaction="/command/comment-edit">
					</div>
					<div class="approval-comment-top">
						<a hef=".show($info.original-url)">original-article</a>
			 		</div>
				</div>
			</form>
		</div>
	.end(for-comments-for-approval)

	</div>
.end()

</div>
.end(if-illegal)