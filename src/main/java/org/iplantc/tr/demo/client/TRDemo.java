package org.iplantc.tr.demo.client;

import org.iplantc.tr.demo.client.panels.TRSearchPanel;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.RootPanel;

/**
 * Entry point classes define <code>onModuleLoad()</code>.
 */
public class TRDemo implements EntryPoint
{
	/**
	 * This is the entry point method.
	 */
	public void onModuleLoad()
	{
		setEntryPointTitle();

		ApplicationLayout layoutApplication = new ApplicationLayout();
		layoutApplication.replaceCenterPanel(new TRSearchPanel());

		RootPanel.get().add(layoutApplication);
	}

	private void setEntryPointTitle()
	{
		Window.setTitle("TR Demo");
	}
}