/**
 * VIEW: Document Summary
 * 
 */

var template = require('./templates/documentHighlight.tpl');

module.exports = Backbone.Marionette.ItemView.extend({

  //--------------------------------------
  //+ PUBLIC PROPERTIES / CONSTANTS
  //--------------------------------------

  tagName: "li",
  className: "clearfix",
  template: template,

  templateHelpers: function(){
    var $projectData = $('body').data(),
        baseUrl;

    if ($projectData.editable){
      baseUrl = aeolus.baseRoot + "/documents/" + this.docId;
    } else {
      baseUrl = aeolus.baseRoot + "/projects/" + $projectData.slug + "/comb?document_id=" + this.docId;
    }

    return {
      pageURL: baseUrl
    };
  },

  //--------------------------------------
  //+ INHERITED / OVERRIDES
  //--------------------------------------

  initialize: function(options){
    this.docId = options.documentId;
  }

  //--------------------------------------
  //+ PUBLIC METHODS / GETTERS / SETTERS
  //--------------------------------------

  //--------------------------------------
  //+ EVENT HANDLERS
  //--------------------------------------

  //--------------------------------------
  //+ PRIVATE AND PROTECTED METHODS
  //--------------------------------------

});