function tos ()
{
	var tos = document.getElementById ('accept_terms_of_service');
	if (tos != null)
	{
	tos.innerHTML = "I accept the <a href=# onClick='SignupSwitchView(2)'>Terms and Conditions</a>"
	}	
}

function hide_forgot_password()
{
	var pw = document.getElementById ('forgot_password');
	if (pw != null)
	{
		pw.innerHTML = "";
	}	
}

function SignupSwitchView (view)
{
	var view_main = document.getElementById ('view_main');
	var view_questions = document.getElementById ('view_questions');

	var signup_content = document.getElementById ('signup_content');
	var login = document.getElementById('user_login')
	

	if (view == view_main)
	{
		view_main.className = 'selected';
		view_questions.className = 'unselected';
		
		if (document.getElementById) 
		{
			document.getElementById('signup_content').style.visibility = 'visible';
			document.getElementById('signup_content').style.display  = 'block';			

			document.getElementById('detail_content').style.visibility = 'hidden';
  		document.getElementById('detail_content').style.display = 'none';
   	}		
	}
	else if (view == view_questions)
	{
		view_main.className = 'unselected';
		view_questions.className = 'selected';
		
		document.getElementById('signup_content').style.visibility = 'hidden';
		document.getElementById('signup_content').style.display  = 'none';			
					
		document.getElementById('detail_content').style.visibility = 'visible';
 		document.getElementById('detail_content').style.display = 'block';		
		
	}	
	
}

function page_unload(evt) {
  //window.external.browsal_failed(); //failure
}  

function page_complete() {
  if (window.external.browsal_complete)
     window.external.browsal_complete(); //success
}  

function page_failed() {
  if (window.external.browsal_failed)
     window.external.browsal_failed(); //failed
}  
