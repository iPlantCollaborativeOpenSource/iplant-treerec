package org.iplantc.tr.demo.client.commands;

import org.iplantc.tr.demo.client.windows.TRViewerWindow;

public class ViewTRResultCommand implements ClientCommand
{

	@Override
	public void execute(String params)
	{
		doView(params);
	}

	private void doView(final String params)
	{
		if(params != null)
		{
			TRViewerWindow win = new TRViewerWindow(params);
			win.show();
			win.setSize(500,500);
			win.setResizable(true);
		}
	}
}
