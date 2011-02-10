package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.panels.TreeContainerPanel;

import com.extjs.gxt.ui.client.event.WindowEvent;
import com.extjs.gxt.ui.client.event.WindowListener;
import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class TRViewerWindow extends Window
{
	private TreeContainerPanel pnl;

	public TRViewerWindow(final String idGene)
	{
		setLayout(new FitLayout());
		pnl = new TreeContainerPanel(idGene);

		addWindowListener(new WindowListener()
		{
			public void windowHide(WindowEvent we)
			{
				pnl.cleanup();
			}
		});

		compose();
	}

	private void compose()
	{
		add(pnl);
	}
}
