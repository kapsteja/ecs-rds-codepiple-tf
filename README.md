added 

-->replaced GItHUB instaed of code commit
-->pulled jdk image and pushed into ecr and used that image in docker: FROM
-->added role policy in codebuild.tf to fetch the jdk image from our local ECR
-->changed buildspec file for our customization
--> added artifact file "imagedefination.json" in codebuild file

