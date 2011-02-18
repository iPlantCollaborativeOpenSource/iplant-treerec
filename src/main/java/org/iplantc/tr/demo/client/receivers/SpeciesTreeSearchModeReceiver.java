package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.commands.ViewTRResultCommand;
import org.iplantc.tr.demo.client.services.SearchService;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;
import org.iplantc.tr.demo.client.utils.JsonUtil;
import org.iplantc.tr.demo.client.windows.TRSearchResultsWindow;

import com.extjs.gxt.ui.client.widget.MessageBox;
import com.google.gwt.core.client.GWT;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.rpc.AsyncCallback;

public class SpeciesTreeSearchModeReceiver extends TreeReceiver
{
	private final SearchServiceAsync searchService = GWT.create(SearchService.class);
	
	public SpeciesTreeSearchModeReceiver(EventBus eventbus, String id)
	{
		super(eventbus, id);
		// TODO Auto-generated constructor stub
	}

	@Override
	protected void processChannelMessage(String idBroadcaster, String jsonMsg)
	{
		JSONObject objJson = JsonUtil.getObject(jsonMsg);

		if(objJson != null)
		{
			if(isOurEvent(idBroadcaster))
			{
				String event = JsonUtil.getString(objJson, "event");

				System.out.println("event-->" + event.toString());

				if(event.equals("branch_clicked"))
				{
					handleBranchClick(objJson);
				}

				if(event.equals("node_mouse_over") || event.equals("leaf_mouse_over")
						|| event.equals("branch_mouse_over") || event.equals("label_mouse_over"))
				{
					handleNodeMouseOver(objJson);
				}

				if(event.equals("node_mouse_out") || event.equals("leaf_mouse_out")
						|| event.equals("branch_mouse_out") || event.equals("label_mouse_out"))
				{
					handleNodeMouseOut(objJson);
				}

			}
		}

	}

	private void handleBranchClick(JSONObject objJson)
	{
		JSONValue id = objJson.get("id");
		if (id != null)
		{
			JSONString idStr = id.isString();
			if (idStr != null)
			{
				duplicationSearch(idStr.stringValue());
			}
		}
	}

	private void duplicationSearch(String nodeId)
	{
	
		final MessageBox wait = MessageBox.wait("Searching", "Searching for Duplication Events", "Searching...");
		wait.show();
		searchService.doDuplicationSearch(nodeId, new AsyncCallback<String>()
		{

			@Override
			public void onFailure(Throwable arg0)
			{
				wait.close();
				String err = "Duplication search failed";
				MessageBox.alert("Error", err, null);
			}

			@Override
			public void onSuccess(String result)
			{
				wait.close();
				showResultsWindow(result);
			}
		});
	}
	
	private void showResultsWindow(String result)
	{
		TRSearchResultsWindow window = TRSearchResultsWindow.getInstance();

		window.init("Duplication Events", result, false, new ViewTRResultCommand(), searchService);

		window.show();
		window.toFront();
>>>>>>> 05b920e23bbc535fdf3ca7cde0555799b0b83d33:src/main/java/org/iplantc/tr/demo/client/receivers/SpeciesTreeSearchModeReceiver.java
	}

}
