package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.panels.TestContainerPanel;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class TRViewerWindow extends Window
{
	public TRViewerWindow(final String idGene)
	{
		setLayout(new FitLayout());
		add(new TestContainerPanel(idGene));
	}
}
