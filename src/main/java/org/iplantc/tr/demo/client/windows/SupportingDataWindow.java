package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.panels.TRDetailsPanel;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class SupportingDataWindow extends Window
{
	public SupportingDataWindow(TRDetailsPanel pnl, String idGeneFamily)
	{
		init(pnl, idGeneFamily);
	}

	private void init(TRDetailsPanel pnl, String idGeneFamily)
	{
		setLayout(new FitLayout());
		setHeading("Supporting Data for Gene Family " + idGeneFamily);
		setSize(400, 220);

		add(pnl);
	}
}
