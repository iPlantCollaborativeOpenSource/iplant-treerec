package org.iplantc.tr.demo.client;

import org.iplantc.tr.demo.client.panels.TestContainerPanel;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class TRViewerWindow extends Window
{
	private TestContainerPanel pnl;

	public TRViewerWindow(SearchServiceAsync searchService, String idGene) {
		setLayout(new FitLayout());
		pnl = new TestContainerPanel();
		add(pnl);
		setSize(936, 596);
	}
}
