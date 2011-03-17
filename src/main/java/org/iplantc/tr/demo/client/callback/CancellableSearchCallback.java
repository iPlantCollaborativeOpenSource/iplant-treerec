package org.iplantc.tr.demo.client.callback;


import com.google.gwt.user.client.rpc.AsyncCallback;

public class CancellableSearchCallback implements AsyncCallback<String>{
	
	protected boolean cancelled = false;

	
	
	@Override
	public void onFailure(Throwable arg0)
	{
		
	}

	@Override
	public void onSuccess(String result)
	{
		
		
	}

	public void enable(){
		cancelled=false;
	}

	public void cancel() {
		cancelled=true;
	}
	
	
}