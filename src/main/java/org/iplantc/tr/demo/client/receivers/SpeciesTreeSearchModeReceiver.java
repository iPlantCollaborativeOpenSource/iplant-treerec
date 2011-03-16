package org.iplantc.tr.demo.client.receivers;

import org.iplantc.tr.demo.client.ContinousProgressBar;
import org.iplantc.tr.demo.client.commands.ClientCommand;
import org.iplantc.tr.demo.client.commands.ViewTRResultCommand;
import org.iplantc.tr.demo.client.services.SearchService;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;
import org.iplantc.tr.demo.client.utils.JsonUtil;
import org.iplantc.tr.demo.client.windows.TRSearchResultsWindow;

import com.extjs.gxt.ui.client.Style;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.ComponentEvent;
import com.extjs.gxt.ui.client.event.EventType;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.Dialog;
import com.extjs.gxt.ui.client.widget.MessageBox;
import com.extjs.gxt.ui.client.widget.ProgressBar;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.layout.BorderLayout;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.google.gwt.core.client.GWT;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.Timer;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.ui.Label;

public class SpeciesTreeSearchModeReceiver extends TreeReceiver
{
	private final SearchServiceAsync searchService = GWT.create(SearchService.class);
	private  SearchCallback searchCallback;
	private SearchingDialog searchingDialog;

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

		searchingDialog = new SearchingDialog(new StopSearchCommand());
		//wait.setProgressText("Searching");


		searchingDialog.setHideOnButtonClick(true);

		searchCallback = new SearchCallback();

		searchingDialog.show();
		searchService.doDuplicationSearch(nodeId, searchCallback);
	}

	private void showResultsWindow(String result)
	{
		TRSearchResultsWindow window = TRSearchResultsWindow.getInstance();

		window.init("Duplication Events", result, false, new ViewTRResultCommand(), searchService);
		window.layout();
		window.show();
		window.toFront();
	}

	class SearchingDialog extends Dialog{

		private ClientCommand cmdCancel;
		
		public SearchingDialog(ClientCommand cmdCancel) {
			super();

			this.cmdCancel =cmdCancel;
			init();
			compose();
		}

		public void init() {
			
			
			
			setHeading("Searching");
			setSize(250, 120);
			
		}

		public void compose() {
			VerticalPanel panel = new VerticalPanel();
			Label text = new Label("Searching for Duplication Events");
			ContinousProgressBar progress = new ContinousProgressBar("Searching...");
			progress.setBorders(false);
			panel.setBorders(false);
			setBorders(false);
			panel.add(text);
			panel.add(progress);
			
			setLayout(new FitLayout());
			
			
			
			setButtons(Dialog.CANCEL);
			Button cancel = getButtonById(Dialog.CANCEL);
			
			cancel.addSelectionListener(new SelectionListener<ButtonEvent>() {
				
				@Override
				public void componentSelected(ButtonEvent ce) {
				 	hide();
					
				}
			});
			
			addListener(Events.Hide, new Listener<ComponentEvent>() {
				
				public void handleEvent(ComponentEvent be) {
					cmdCancel.execute("");
				};
				
			});

			add(panel);
			progress.start();
			layout();
		}


	}
	
	class SearchCallback implements AsyncCallback<String>{
		
		boolean cancelled = false;

		@Override
		public void onFailure(Throwable arg0)
		{
			searchingDialog.hide();
			String err = "Duplication search failed";
			MessageBox.alert("Error", err, null);
		}

		@Override
		public void onSuccess(String result)
		{
			
			if(!cancelled) {
				showResultsWindow(result);
			}
			searchingDialog.hide();
		}


		public void cancel() {
			cancelled=true;
		}
		
		
	}

	
	class StopSearchCommand implements ClientCommand{
		
		@Override
		public void execute(String params) {
			searchCallback.cancel();
			
		}
		
	}

}
