package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.panels.TestContainerPanel;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class TRViewerWindow extends Window
{
	private TestContainerPanel pnl;

	public TRViewerWindow(SearchServiceAsync searchService, String idGene) {
		setLayout(new FitLayout());
		pnl = new TestContainerPanel();
		add(pnl);
	}
}
